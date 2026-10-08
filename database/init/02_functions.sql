-- ========================================================
-- 02_functions.sql: PROCEDIMIENTOS ALMACENADOS & LÓGICA ATÓMICA
-- PROYECTO: Andrés Peluquería - Sistema Agendamiento con IA
-- ========================================================

-- --------------------------------------------------------
-- 1. FUNCIÓN DE GESTIÓN DE CLIENTE Y CONVERSACIÓN
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION obtener_o_crear_cliente(
    p_wa_id VARCHAR(30),
    p_nombre VARCHAR(120) DEFAULT NULL
)
RETURNS TABLE (
    cliente_id UUID,
    conversacion_id UUID,
    estado_conversacion VARCHAR(30),
    es_nuevo BOOLEAN
) AS $$
DECLARE
    v_cliente_id UUID;
    v_conversacion_id UUID;
    v_estado VARCHAR(30);
    v_es_nuevo BOOLEAN := FALSE;
BEGIN
    -- Buscar o insertar cliente
    SELECT id INTO v_cliente_id FROM clientes WHERE wa_id = p_wa_id;
    
    IF v_cliente_id IS NULL THEN
        INSERT INTO clientes (wa_id, nombre) 
        VALUES (p_wa_id, COALESCE(p_nombre, 'Cliente WhatsApp'))
        RETURNING id INTO v_cliente_id;
        v_es_nuevo := TRUE;
    ELSE
        IF p_nombre IS NOT NULL AND p_nombre <> '' THEN
            UPDATE clientes SET nombre = p_nombre, actualizado_en = CURRENT_TIMESTAMP WHERE id = v_cliente_id;
        END IF;
    END IF;

    -- Buscar conversación activa o crear una nueva
    SELECT id, estado INTO v_conversacion_id, v_estado 
    FROM conversaciones 
    WHERE cliente_id = v_cliente_id 
    ORDER BY ultimo_mensaje_en DESC 
    LIMIT 1;

    IF v_conversacion_id IS NULL OR v_estado = 'cerrada' THEN
        INSERT INTO conversaciones (cliente_id, estado) 
        VALUES (v_cliente_id, 'activa')
        RETURNING id, estado INTO v_conversacion_id, v_estado;
    ELSE
        UPDATE conversaciones SET ultimo_mensaje_en = CURRENT_TIMESTAMP WHERE id = v_conversacion_id;
    END IF;

    RETURN QUERY SELECT v_cliente_id, v_conversacion_id, v_estado, v_es_nuevo;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------
-- 2. FUNCIÓN ATÓMICA DE DEBOUNCE (CONSUMIR COLA AGRUPADA)
-- Agrupa múltiples mensajes en ráfaga enviados en menos de 5 segundos
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION consumir_cola_debounce(
    p_wa_id VARCHAR(30)
)
RETURNS TABLE (
    mensajes_agrupados TEXT,
    total_mensajes INT
) AS $$
DECLARE
    v_texto_unificado TEXT;
    v_conteo INT;
BEGIN
    -- Concatenar mensajes pendientes
    SELECT 
        string_agg(texto, E'\n' ORDER BY recibido_en ASC),
        count(*)
    INTO 
        v_texto_unificado,
        v_conteo
    FROM cola_mensajes_debounce
    WHERE wa_id = p_wa_id AND procesado = FALSE;

    -- Marcar como procesados atómicamente
    IF v_conteo > 0 THEN
        UPDATE cola_mensajes_debounce
        SET procesado = TRUE
        WHERE wa_id = p_wa_id AND procesado = FALSE;
    END IF;

    RETURN QUERY SELECT v_texto_unificado, v_conteo;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------
-- 3. FUNCIÓN PARA VERIFICAR SOLAPAMIENTO DE CITAS (ANTI-DOBLE BOOKING)
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION verificar_solapamiento_cita(
    p_fecha_inicio TIMESTAMP WITH TIME ZONE,
    p_fecha_fin TIMESTAMP WITH TIME ZONE
)
RETURNS BOOLEAN AS $$
DECLARE
    v_conflicto INT;
BEGIN
    SELECT COUNT(*) INTO v_conflicto
    FROM citas
    WHERE estado = 'confirmada'
      AND (
          (fecha_inicio < p_fecha_fin AND fecha_fin > p_fecha_inicio)
      );

    RETURN (v_conflicto > 0); -- TRUE si hay conflicto, FALSE si está libre
END;
$$ LANGUAGE plpgsql;
