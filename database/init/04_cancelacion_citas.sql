-- ========================================================
-- 04_cancelacion_citas.sql: CANCELACIÓN ATÓMICA DE CITAS (Postgres manda)
-- PROYECTO: Andrés Peluquería - Sistema Agendamiento con IA
-- Usada por: T-04 (cliente por WhatsApp), TG-02 (/cancelar de Andrés)
--            y C-02 (cambio de Estado en Google Sheets).
-- Idempotente: se puede ejecutar varias veces.
-- ========================================================

CREATE OR REPLACE FUNCTION cancelar_cita(
    p_ref TEXT DEFAULT NULL,        -- código de la cita (primeros caracteres de su UUID, con o sin #)
    p_wa_id TEXT DEFAULT NULL,      -- si no hay código: se cancela la próxima cita de este cliente
    p_forzar BOOLEAN DEFAULT FALSE  -- TRUE = administrador (sin regla de 2 horas)
)
RETURNS TABLE (
    out_ok BOOLEAN,
    out_codigo TEXT,
    out_mensaje TEXT,
    out_cita_id UUID,
    out_fecha_inicio TIMESTAMPTZ,
    out_servicio_nombre TEXT,
    out_cliente_nombre TEXT,
    out_wa_id TEXT,
    out_precio NUMERIC,
    out_citas_restantes INT
) AS $$
DECLARE
    v_ref   TEXT := lower(regexp_replace(trim(COALESCE(p_ref, '')), '^#', ''));
    v_wa    TEXT := regexp_replace(COALESCE(p_wa_id, ''), '\D', '', 'g');
    v_cita  citas%ROWTYPE;
    v_n     INT;
BEGIN
    IF v_ref = '' AND v_wa = '' THEN
        out_ok := FALSE; out_codigo := 'REFERENCIA_REQUERIDA';
        out_mensaje := 'Falta el código de la cita.';
        RETURN NEXT; RETURN;
    END IF;

    -- 1) Localizar la cita
    IF v_ref <> '' THEN
        IF v_ref !~ '^[0-9a-f-]{4,36}$' THEN
            out_ok := FALSE; out_codigo := 'NO_ENCONTRADA';
            out_mensaje := 'No existe una cita con ese código.';
            RETURN NEXT; RETURN;
        END IF;

        SELECT count(*) INTO v_n FROM citas ci WHERE ci.id::text LIKE v_ref || '%';
        IF v_n = 0 THEN
            out_ok := FALSE; out_codigo := 'NO_ENCONTRADA';
            out_mensaje := 'No existe una cita con ese código.';
            RETURN NEXT; RETURN;
        ELSIF v_n > 1 THEN
            out_ok := FALSE; out_codigo := 'REFERENCIA_AMBIGUA';
            out_mensaje := 'Ese código coincide con varias citas. Usa más caracteres.';
            RETURN NEXT; RETURN;
        END IF;

        SELECT * INTO v_cita FROM citas ci WHERE ci.id::text LIKE v_ref || '%';
    ELSE
        SELECT ci.* INTO v_cita
        FROM citas ci
        JOIN clientes cl ON cl.id = ci.cliente_id
        WHERE regexp_replace(cl.wa_id, '\D', '', 'g') = v_wa
          AND ci.estado = 'confirmada'
          AND ci.fecha_fin > now()
        ORDER BY ci.fecha_inicio ASC
        LIMIT 1;

        IF NOT FOUND THEN
            out_ok := FALSE; out_codigo := 'NO_ENCONTRADA';
            out_mensaje := 'No encontré ninguna cita activa para cancelar. Si crees que se trata de un error, con gusto le aviso a Andrés.';
            RETURN NEXT; RETURN;
        END IF;
    END IF;

    -- 2) Datos de la cita para respuestas y avisos
    out_cita_id := v_cita.id;
    out_fecha_inicio := v_cita.fecha_inicio;

    SELECT s.nombre, s.precio_base_cop
    INTO out_servicio_nombre, out_precio
    FROM servicios s WHERE s.id = v_cita.servicio_id;

    SELECT COALESCE(NULLIF(trim(substring(v_cita.notas from 'Titular: ([^|]*)')), ''), cl.nombre), cl.wa_id
    INTO out_cliente_nombre, out_wa_id
    FROM clientes cl WHERE cl.id = v_cita.cliente_id;

    -- 3) Reglas de negocio
    IF v_cita.estado = 'cancelada' THEN
        out_ok := TRUE; out_codigo := 'YA_CANCELADA';
        out_mensaje := 'La cita ya estaba cancelada.';
        RETURN NEXT; RETURN;
    END IF;

    IF v_cita.estado <> 'confirmada' THEN
        out_ok := FALSE; out_codigo := 'NO_CANCELABLE';
        out_mensaje := 'Esa cita está en estado ' || v_cita.estado || ' y no se puede cancelar.';
        RETURN NEXT; RETURN;
    END IF;

    -- Regla de 2 horas de anticipación (con ventana de cortesía de 15 minutos si la acaba de agendar)
    IF NOT p_forzar
       AND (v_cita.fecha_inicio - now() < INTERVAL '2 hours')
       AND (now() - v_cita.creada_en > INTERVAL '15 minutes') THEN
        out_ok := FALSE; out_codigo := 'MENOS_DE_2_HORAS';
        out_mensaje := 'Por políticas de Andrés Peluquería, las cancelaciones automáticas deben realizarse con un mínimo de 2 horas de anticipación. Como faltan menos de 2 horas para tu cita, por favor comunícate directamente con Andrés para revisar tu caso.';
        RETURN NEXT; RETURN;
    END IF;

    -- 4) Cancelar
    UPDATE citas ci
    SET estado = 'cancelada',
        actualizada_en = CURRENT_TIMESTAMP,
        notas = COALESCE(ci.notas, '') || ' | Cancelada ' || to_char(now() AT TIME ZONE 'America/Bogota', 'YYYY-MM-DD HH24:MI')
    WHERE ci.id = v_cita.id AND ci.estado = 'confirmada';

    SELECT count(*)::INT INTO out_citas_restantes
    FROM citas ci
    WHERE ci.cliente_id = v_cita.cliente_id
      AND ci.estado = 'confirmada'
      AND ci.fecha_fin > now();

    out_ok := TRUE; out_codigo := 'CANCELADA';
    out_mensaje := 'Cita cancelada.';
    RETURN NEXT; RETURN;
END;
$$ LANGUAGE plpgsql;
