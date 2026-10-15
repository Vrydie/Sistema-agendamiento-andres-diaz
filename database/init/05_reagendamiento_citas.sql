-- ========================================================
-- 05_reagendamiento_citas.sql: REAGENDAMIENTO ATÓMICO Y EXCLUSIÓN DE CITA PROPIA
-- PROYECTO: Andrés Peluquería - Sistema Agendamiento con IA
-- Idempotente: se puede ejecutar varias veces.
-- ========================================================

-- 1. CONSULTAR DISPONIBILIDAD (Con soporte opcional para ignorar cita del cliente que reagenda)
CREATE OR REPLACE FUNCTION consultar_disponibilidad(
    p_fecha DATE,
    p_duracion_min INT,
    p_wa_id TEXT DEFAULT NULL
)
RETURNS TABLE (slot_inicio TIMESTAMPTZ, slot_fin TIMESTAMPTZ) AS $$
DECLARE
    v_tz CONSTANT TEXT := 'America/Bogota';
    v_clean_wa TEXT := regexp_replace(COALESCE(p_wa_id, ''), '\D', '', 'g');
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
          LEFT JOIN clientes cl ON cl.id = c.cliente_id
          WHERE c.estado = 'confirmada'
            -- Si se pasa wa_id, excluimos las citas propias del cliente para permitir reagendar
            AND (v_clean_wa = '' OR regexp_replace(COALESCE(cl.wa_id, ''), '\D', '', 'g') <> v_clean_wa)
            AND c.fecha_inicio < g.ini + make_interval(mins => p_duracion_min)
            AND c.fecha_fin > g.ini
      )
    ORDER BY g.ini;
END;
$$ LANGUAGE plpgsql STABLE;

-- 2. REAGENDAR CITA ATÓMICA
CREATE OR REPLACE FUNCTION reagendar_cita_atomica(
    p_wa_id VARCHAR,
    p_nueva_fecha_inicio TIMESTAMPTZ,
    p_nuevo_servicio TEXT DEFAULT NULL
)
RETURNS TABLE (
    out_ok BOOLEAN,
    out_codigo TEXT,
    out_mensaje TEXT,
    out_cita_id UUID,
    out_fecha_anterior TIMESTAMPTZ,
    out_nueva_fecha_inicio TIMESTAMPTZ,
    out_nueva_fecha_fin TIMESTAMPTZ,
    out_servicio_nombre TEXT,
    out_cliente_nombre TEXT,
    out_wa_id TEXT,
    out_precio NUMERIC,
    out_alternativas TEXT
) AS $$
DECLARE
    v_tz        CONSTANT TEXT := 'America/Bogota';
    v_srv       servicios%ROWTYPE;
    v_cita      citas%ROWTYPE;
    v_cliente   clientes%ROWTYPE;
    v_wa        TEXT := regexp_replace(COALESCE(p_wa_id, ''), '\D', '', 'g');
    v_local     TIMESTAMP;
    v_fin       TIMESTAMPTZ;
    v_conflicto BOOLEAN := FALSE;
    v_alt       TEXT;
    v_nombre    TEXT;
BEGIN
    -- 1) Buscar el cliente
    SELECT * INTO v_cliente
    FROM clientes
    WHERE regexp_replace(wa_id, '\D', '', 'g') = v_wa
    LIMIT 1;

    IF NOT FOUND THEN
        out_ok := FALSE; out_codigo := 'CLIENTE_NO_ENCONTRADO';
        out_mensaje := 'No encontré un registro previo de cliente con tu número. ¿Deseas agendar una cita nueva?';
        RETURN NEXT; RETURN;
    END IF;

    -- 2) Buscar cita activa más próxima
    SELECT * INTO v_cita
    FROM citas
    WHERE cliente_id = v_cliente.id
      AND estado = 'confirmada'
      AND fecha_fin > now()
    ORDER BY fecha_inicio ASC
    LIMIT 1;

    IF NOT FOUND THEN
        out_ok := FALSE; out_codigo := 'SIN_CITA_ACTIVA';
        out_mensaje := 'No encontré ninguna cita activa confirmada para modificar. ¿Deseas que te ayude a agendar una cita nueva?';
        RETURN NEXT; RETURN;
    END IF;

    -- Extraer nombre del cliente
    v_nombre := COALESCE(NULLIF(trim(substring(v_cita.notas from 'Titular: ([^|]*)')), ''), v_cliente.nombre, 'Cliente');

    -- 3) Resolver servicio (nuevo o mantener el de la cita existente)
    IF p_nuevo_servicio IS NOT NULL AND trim(p_nuevo_servicio) <> '' THEN
        SELECT * INTO v_srv FROM resolver_servicio(p_nuevo_servicio);
    ELSE
        SELECT * INTO v_srv FROM servicios WHERE id = v_cita.servicio_id;
    END IF;

    IF v_srv.id IS NULL THEN
        SELECT * INTO v_srv FROM servicios WHERE id = v_cita.servicio_id;
    END IF;

    -- 4) Validación temporal y de huso horario
    IF p_nueva_fecha_inicio IS NULL THEN
        out_ok := FALSE; out_codigo := 'FECHA_INVALIDA';
        out_mensaje := 'Por favor indícame la nueva fecha y hora exacta en que te gustaría tu cita.';
        RETURN NEXT; RETURN;
    END IF;

    -- Bloquear pasado e inmediatez (< 30 min)
    IF p_nueva_fecha_inicio < (now() + INTERVAL '30 minutes') THEN
        out_ok := FALSE; out_codigo := 'FECHA_INVALIDA';
        out_mensaje := 'Las citas deben programarse con al menos 30 minutos de anticipación. Por favor elige otro horario.';
        RETURN NEXT; RETURN;
    END IF;

    v_local := p_nueva_fecha_inicio AT TIME ZONE v_tz;

    -- Bloquear Domingos y festivos
    IF EXTRACT(ISODOW FROM v_local) = 7 OR es_festivo_colombia(v_local::date) THEN
        out_ok := FALSE; out_codigo := 'DIA_NO_LABORAL';
        out_mensaje := 'Los domingos y días festivos no tenemos servicio en el salón. Nuestro horario de atención es de lunes a sábado de 9:00 AM a 8:00 PM. ¿Te gustaría agendar para otro día hábil?';
        RETURN NEXT; RETURN;
    END IF;

    -- Validar horario comercial (09:00 a 20:00)
    IF (v_local::time < TIME '09:00') OR
       ((v_local + make_interval(mins => v_srv.duracion_minutos)) > (date_trunc('day', v_local) + TIME '20:00')) THEN
        out_ok := FALSE; out_codigo := 'FUERA_DE_HORARIO';
        out_mensaje := 'El horario de atención es de 9:00 AM a 8:00 PM y el servicio ' || v_srv.nombre || ' dura ' || v_srv.duracion_minutos || ' minutos. Por favor elige un turno que termine antes de las 8:00 PM.';
        RETURN NEXT; RETURN;
    END IF;

    -- 5) Serializar con advisory lock para evitar colisiones concurrentes
    PERFORM pg_advisory_xact_lock(727001);

    v_fin := p_nueva_fecha_inicio + make_interval(mins => v_srv.duracion_minutos);

    -- 6) Verificar solapamiento excluyendo la cita actual del cliente
    IF EXISTS (
        SELECT 1
        FROM citas c
        WHERE c.estado = 'confirmada'
          AND c.id <> v_cita.id -- << No colisiona consigo misma
          AND c.fecha_inicio < v_fin
          AND c.fecha_fin > p_nueva_fecha_inicio
    ) THEN
        v_conflicto := TRUE;
    END IF;

    -- 7) Si hay colisión con otra cita externa, buscar alternativas libres
    IF v_conflicto THEN
        SELECT string_agg(to_char(slot_inicio AT TIME ZONE v_tz, 'HH12:MI AM'), ', ')
        INTO v_alt
        FROM (
            SELECT slot_inicio
            FROM consultar_disponibilidad(v_local::date, v_srv.duracion_minutos, v_wa)
            ORDER BY @ EXTRACT(EPOCH FROM (slot_inicio - p_nueva_fecha_inicio))
            LIMIT 3
        ) s;

        out_ok := FALSE;
        out_codigo := 'HORARIO_OCUPADO';
        out_mensaje := 'Ese nuevo horario ya está ocupado por otro cliente.' ||
            CASE WHEN v_alt IS NOT NULL AND v_alt <> ''
                 THEN ' Tengo disponibles estos turnos cercanos: ' || v_alt || '. ¿Te sirve alguno?'
                 ELSE ' No hay más turnos disponibles para ese día. ¿Te gustaría revisar otro día?'
            END;
        out_alternativas := v_alt;
        out_cita_id := v_cita.id;
        out_fecha_anterior := v_cita.fecha_inicio;
        out_cliente_nombre := v_nombre;
        out_wa_id := v_wa;
        RETURN NEXT; RETURN;
    END IF;

    -- 8) Actualizar la cita existente de forma atómica
    UPDATE citas
    SET fecha_inicio = p_nueva_fecha_inicio,
        fecha_fin = v_fin,
        servicio_id = v_srv.id,
        actualizada_en = CURRENT_TIMESTAMP,
        notas = COALESCE(v_cita.notas, '') || ' | Reagendada ' ||
                to_char(v_cita.fecha_inicio AT TIME ZONE v_tz, 'YYYY-MM-DD HH24:MI') ||
                ' -> ' ||
                to_char(p_nueva_fecha_inicio AT TIME ZONE v_tz, 'YYYY-MM-DD HH24:MI')
    WHERE id = v_cita.id;

    -- 9) Retornar resultado exitoso
    out_ok := TRUE;
    out_codigo := 'REAGENDADA';
    out_cita_id := v_cita.id;
    out_fecha_anterior := v_cita.fecha_inicio;
    out_nueva_fecha_inicio := p_nueva_fecha_inicio;
    out_nueva_fecha_fin := v_fin;
    out_servicio_nombre := v_srv.nombre;
    out_cliente_nombre := v_nombre;
    out_wa_id := v_wa;
    out_precio := v_srv.precio_base_cop;
    out_mensaje := '¡Listo! Tu cita para ' || v_srv.nombre || ' quedó reprogramada para el ' ||
                   to_char(v_local, 'TMDay, DD de TMMonth') || ' a las ' ||
                   to_char(v_local, 'HH12:MI AM') || '. ¡Te esperamos!';
    RETURN NEXT; RETURN;
END;
$$ LANGUAGE plpgsql;
