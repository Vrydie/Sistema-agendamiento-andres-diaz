-- ========================================================
-- 03_agendamiento_atomico.sql: DISPONIBILIDAD Y AGENDAMIENTO ATÓMICO
-- PROYECTO: Andrés Peluquería - Sistema Agendamiento con IA
-- Regla 1: "El LLM es impredecible, la Base de Datos no".
-- Idempotente: se puede ejecutar varias veces (CREATE OR REPLACE / IF NOT EXISTS).
-- Para una BD ya en producción:  psql -f database/init/03_agendamiento_atomico.sql
-- ========================================================

-- --------------------------------------------------------
-- 0. ÍNDICE PARA EL CRON DE RECORDATORIOS (solo filas pendientes)
-- --------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_citas_recordatorio_pendiente
    ON citas (fecha_inicio)
    WHERE estado = 'confirmada' AND recordatorio_enviado = FALSE;

-- --------------------------------------------------------
-- 1. BLINDAJE FINAL: la BD rechaza dos citas confirmadas que se solapen
--    (si ya hay datos solapados, se omite con un aviso y no rompe el script)
-- --------------------------------------------------------
DO $$
BEGIN
    ALTER TABLE citas
        ADD CONSTRAINT citas_sin_solapamiento
        EXCLUDE USING gist (tstzrange(fecha_inicio, fecha_fin, '[)') WITH &&)
        WHERE (estado = 'confirmada');
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- ya existe
    WHEN exclusion_violation THEN
        RAISE NOTICE 'No se creó citas_sin_solapamiento: ya existen citas confirmadas solapadas. Cancela las duplicadas y vuelve a ejecutar.';
END;
$$;

-- --------------------------------------------------------
-- 2. RESOLVER SERVICIO A PARTIR DE TEXTO LIBRE DEL LLM
--    ('corte de puntas' -> corte_styling, 'mechas' -> balayage_signature, ...)
--    Devuelve 0 filas si no reconoce nada (nunca asume un servicio al azar).
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION resolver_servicio(p_texto TEXT)
RETURNS SETOF servicios AS $$
DECLARE
    v_txt    TEXT := lower(trim(COALESCE(p_texto, '')));
    v_codigo TEXT;
BEGIN
    IF v_txt = '' THEN
        RETURN;
    END IF;

    -- 1) Código exacto
    RETURN QUERY SELECT s.* FROM servicios s WHERE s.activo AND s.codigo = v_txt LIMIT 1;
    IF FOUND THEN RETURN; END IF;

    -- 2) Nombre del catálogo
    RETURN QUERY SELECT s.* FROM servicios s WHERE s.activo AND s.nombre ILIKE '%' || v_txt || '%' LIMIT 1;
    IF FOUND THEN RETURN; END IF;

    -- 3) Palabras clave
    v_codigo := CASE
        WHEN v_txt ~ '(gloss|matiz|brillo|tono)'                                       THEN 'matiz_gloss'
        WHEN v_txt ~ '(balayage|mecha|rayito|tinte|color|iluminaci|decolor)'          THEN 'balayage_signature'
        WHEN v_txt ~ '(terapia|hidrata|nutri|repara|keratina|cauteri|tratamiento)'    THEN 'terapia_reparacion'
        WHEN v_txt ~ '(corte|punta|peluque|motil|barba|cabello|styling|brushing)'     THEN 'corte_styling'
        ELSE NULL
    END;

    IF v_codigo IS NOT NULL THEN
        RETURN QUERY SELECT s.* FROM servicios s WHERE s.activo AND s.codigo = v_codigo LIMIT 1;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------
-- 2.5 FUNCIÓN AUXILIAR: FESTIVOS OFICIALES EN COLOMBIA
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION es_festivo_colombia(p_fecha DATE)
RETURNS BOOLEAN AS $$
BEGIN
    -- Calendario oficial de festivos Colombia (fijos y Ley Emiliani)
    RETURN p_fecha IN (
        -- 2026
        '2026-01-01', '2026-01-12', '2026-03-23', '2026-04-02', '2026-04-03',
        '2026-05-01', '2026-05-18', '2026-06-08', '2026-06-15', '2026-06-29',
        '2026-07-20', '2026-08-07', '2026-08-17', '2026-10-12', '2026-11-02',
        '2026-11-16', '2026-12-08', '2026-12-25',
        -- 2027
        '2027-01-01', '2027-01-11', '2027-03-22', '2027-03-25', '2027-03-26',
        '2027-05-01', '2027-05-10', '2027-05-31', '2027-06-07', '2027-07-05',
        '2027-07-20', '2027-08-07', '2027-08-16', '2027-10-18', '2027-11-01',
        '2027-11-15', '2027-12-08', '2027-12-25'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- --------------------------------------------------------
-- 3. HORARIOS LIBRES DE UN DÍA (rejilla de 30 min, Lun-Sáb 9:00-20:00 Bogotá)
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION consultar_disponibilidad(
    p_fecha DATE,
    p_duracion_min INT DEFAULT 60
)
RETURNS TABLE (slot_inicio TIMESTAMPTZ, slot_fin TIMESTAMPTZ) AS $$
DECLARE
    v_tz CONSTANT TEXT := 'America/Bogota';
BEGIN
    -- Domingos y festivos cerrado
    IF EXTRACT(ISODOW FROM p_fecha) = 7 OR es_festivo_colombia(p_fecha) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT g.ini,
           g.ini + make_interval(mins => p_duracion_min)
    FROM (
        SELECT (loc AT TIME ZONE v_tz) AS ini, loc
        FROM (
            SELECT (p_fecha + TIME '09:00') + (n * INTERVAL '30 minutes') AS loc
            FROM generate_series(0, 22) AS n
        ) base
    ) g
    WHERE g.loc + make_interval(mins => p_duracion_min) <= (p_fecha + TIME '20:00')
      AND g.ini >= now() + INTERVAL '30 minutes'
      AND NOT EXISTS (
          SELECT 1
          FROM citas c
          WHERE c.estado = 'confirmada'
            AND c.fecha_inicio < g.ini + make_interval(mins => p_duracion_min)
            AND c.fecha_fin > g.ini
      )
    ORDER BY g.ini;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------
-- 4. CREAR CITA ATÓMICA E IDEMPOTENTE
--    Valida horario, serializa con advisory lock, evita doble booking y,
--    si el horario está ocupado, devuelve alternativas REALES.
--    Siempre devuelve exactamente 1 fila (nunca "silencio" hacia el LLM).
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION crear_cita_atomica(
    p_wa_id VARCHAR,
    p_servicio TEXT,
    p_fecha_inicio TIMESTAMPTZ,
    p_nombre_titular TEXT DEFAULT NULL
)
RETURNS TABLE (
    out_ok BOOLEAN,
    out_codigo TEXT,
    out_mensaje TEXT,
    out_cita_id UUID,
    out_fecha_inicio TIMESTAMPTZ,
    out_fecha_fin TIMESTAMPTZ,
    out_servicio_nombre TEXT,
    out_precio NUMERIC,
    out_alternativas TEXT
) AS $$
DECLARE
    v_tz        CONSTANT TEXT := 'America/Bogota';
    v_srv       servicios%ROWTYPE;
    v_cita      citas%ROWTYPE;
    v_cliente   UUID;
    v_wa        TEXT := regexp_replace(COALESCE(p_wa_id, ''), '\D', '', 'g');
    v_local     TIMESTAMP;
    v_fin       TIMESTAMPTZ;
    v_conflicto BOOLEAN := FALSE;
    v_alt       TEXT;
BEGIN
    -- 1) Servicio
    SELECT * INTO v_srv FROM resolver_servicio(p_servicio) LIMIT 1;
    IF NOT FOUND THEN
        out_ok := FALSE; out_codigo := 'SERVICIO_NO_ENCONTRADO';
        out_mensaje := 'No se reconoció el servicio. Pregunta al cliente cuál servicio desea del catálogo.';
        RETURN NEXT; RETURN;
    END IF;
    out_servicio_nombre := v_srv.nombre;
    out_precio := v_srv.precio_base_cop;

    -- 2) Validaciones de negocio
    IF v_wa = '' THEN
        out_ok := FALSE; out_codigo := 'CLIENTE_INVALIDO';
        out_mensaje := 'No se pudo identificar el número de WhatsApp del cliente.';
        RETURN NEXT; RETURN;
    END IF;

    -- Guarda de margen mínimo (Lead Time mínimo de 30 minutos)
    IF p_fecha_inicio IS NULL OR p_fecha_inicio < (now() + INTERVAL '30 minutes') THEN
        out_ok := FALSE; out_codigo := 'FECHA_INVALIDA';
        out_mensaje := 'Las citas deben solicitarse con al menos 30 minutos de anticipación y en una fecha y hora futura. Pide al cliente otro horario.';
        RETURN NEXT; RETURN;
    END IF;

    v_local := p_fecha_inicio AT TIME ZONE v_tz;
    v_fin := p_fecha_inicio + make_interval(mins => v_srv.duracion_minutos);

    IF EXTRACT(ISODOW FROM v_local) = 7
       OR es_festivo_colombia(v_local::DATE)
       OR v_local::TIME < TIME '09:00'
       OR (v_local + make_interval(mins => v_srv.duracion_minutos)) > (date_trunc('day', v_local) + TIME '20:00') THEN
        out_ok := FALSE; out_codigo := 'FUERA_DE_HORARIO';
        out_mensaje := 'Ese horario está fuera de atención (Lunes a Sábado 9:00 AM a 8:00 PM; domingos y festivos cerrado). El servicio debe culminar antes de las 8:00 PM. Ofrece otro horario dentro del rango.';
        RETURN NEXT; RETURN;
    END IF;

    -- 3) Serializar agendamientos concurrentes
    PERFORM pg_advisory_xact_lock(727001);

    -- 4) Cliente (se crea si aún no existe)
    SELECT cl.id INTO v_cliente
    FROM clientes cl
    WHERE regexp_replace(cl.wa_id, '\D', '', 'g') = v_wa
    LIMIT 1;

    IF v_cliente IS NULL THEN
        INSERT INTO clientes (wa_id, nombre)
        VALUES (v_wa, COALESCE(NULLIF(trim(p_nombre_titular), ''), 'Cliente WhatsApp'))
        RETURNING id INTO v_cliente;
    END IF;

    -- 5) Idempotencia: misma cita del mismo cliente ya registrada -> éxito sin duplicar
    SELECT * INTO v_cita
    FROM citas ci
    WHERE ci.cliente_id = v_cliente
      AND ci.estado = 'confirmada'
      AND ci.fecha_inicio = p_fecha_inicio
    LIMIT 1;

    IF FOUND THEN
        out_ok := TRUE; out_codigo := 'YA_EXISTIA';
        out_mensaje := 'La cita ya estaba registrada para ese horario.';
        out_cita_id := v_cita.id; out_fecha_inicio := v_cita.fecha_inicio; out_fecha_fin := v_cita.fecha_fin;
        RETURN NEXT; RETURN;
    END IF;

    -- 6) Solapamiento real contra la agenda
    v_conflicto := EXISTS (
        SELECT 1 FROM citas ci
        WHERE ci.estado = 'confirmada'
          AND ci.fecha_inicio < v_fin
          AND ci.fecha_fin > p_fecha_inicio
    );

    IF NOT v_conflicto THEN
        BEGIN
            INSERT INTO citas (cliente_id, servicio_id, fecha_inicio, fecha_fin, estado, notas)
            VALUES (
                v_cliente, v_srv.id, p_fecha_inicio, v_fin, 'confirmada',
                'Agendado por Asistente IA WhatsApp' ||
                CASE WHEN NULLIF(trim(p_nombre_titular), '') IS NOT NULL
                     THEN ' | Titular: ' || trim(p_nombre_titular) ELSE '' END
            )
            RETURNING * INTO v_cita;
        EXCEPTION WHEN exclusion_violation THEN
            v_conflicto := TRUE;
        END;
    END IF;

    -- 7) Ocupado: devolver alternativas reales (3 más cercanas del mismo día)
    IF v_conflicto THEN
        SELECT string_agg(to_char(a.slot_inicio AT TIME ZONE v_tz, 'FMHH12:MI AM'), ', ' ORDER BY a.dif)
        INTO v_alt
        FROM (
            SELECT d.slot_inicio,
                   abs(extract(epoch FROM (d.slot_inicio - p_fecha_inicio))) AS dif
            FROM consultar_disponibilidad(v_local::DATE, v_srv.duracion_minutos) d
            ORDER BY dif
            LIMIT 3
        ) a;

        out_ok := FALSE; out_codigo := 'HORARIO_OCUPADO';
        out_alternativas := v_alt;
        out_mensaje := CASE WHEN v_alt IS NULL
            THEN 'Ese horario está ocupado y no quedan cupos ese día. Ofrece otro día.'
            ELSE 'Ese horario está ocupado. Alternativas libres ese día: ' || v_alt || '.' END;
        RETURN NEXT; RETURN;
    END IF;

    -- 8) Éxito
    out_ok := TRUE; out_codigo := 'CREADA';
    out_mensaje := 'Cita creada.';
    out_cita_id := v_cita.id; out_fecha_inicio := v_cita.fecha_inicio; out_fecha_fin := v_cita.fecha_fin;
    RETURN NEXT; RETURN;
END;
$$ LANGUAGE plpgsql;
