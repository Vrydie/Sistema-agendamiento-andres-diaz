-- ========================================================
-- 01_schema.sql: ESQUEMA DE BASE DE DATOS POSTGRESQL
-- PROYECTO: Andrés Peluquería - Sistema Agendamiento con IA
-- ESTÁNDAR: Metodología Full-Stack Automator
-- ========================================================

-- Extensión para generar UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- --------------------------------------------------------
-- 1. TABLA DE AUDITORÍA RAW (Regla de Oro: Guardar TODO)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS eventos_webhook (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    origen VARCHAR(50) NOT NULL DEFAULT 'meta_whatsapp',
    payload_raw JSONB NOT NULL,
    procesado BOOLEAN DEFAULT FALSE,
    error_log TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eventos_webhook_procesado ON eventos_webhook(procesado);
CREATE INDEX IF NOT EXISTS idx_eventos_webhook_creado ON eventos_webhook(creado_en DESC);

-- --------------------------------------------------------
-- 2. TABLA DE CLIENTES
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wa_id VARCHAR(30) UNIQUE NOT NULL, -- Número de teléfono internacional (ej: 573001234567)
    nombre VARCHAR(120),
    email VARCHAR(120),
    total_citas INT DEFAULT 0,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_clientes_wa_id ON clientes(wa_id);

-- --------------------------------------------------------
-- 3. TABLA DE COLA DE MENSAJES (PARA DEBOUNCE 3-5 SEGUNDOS)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS cola_mensajes_debounce (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wa_id VARCHAR(30) NOT NULL,
    mensaje_id_externo VARCHAR(100),
    texto TEXT NOT NULL,
    procesado BOOLEAN DEFAULT FALSE,
    recibido_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debounce_wa_procesado ON cola_mensajes_debounce(wa_id, procesado);

-- --------------------------------------------------------
-- 4. CONVERSACIONES Y ESTADO DE SESIÓN
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS conversaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    estado VARCHAR(30) NOT NULL DEFAULT 'activa', -- 'activa', 'pausada_humano', 'cerrada'
    servicio_interes VARCHAR(100),
    pausada_hasta TIMESTAMP WITH TIME ZONE,
    ultimo_mensaje_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creada_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_conversaciones_cliente ON conversaciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_estado ON conversaciones(estado);

-- --------------------------------------------------------
-- 5. HISTORIAL DE MENSAJES (MEMORIA CONVERSACIONAL)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversacion_id UUID NOT NULL REFERENCES conversaciones(id) ON DELETE CASCADE,
    remitente VARCHAR(20) NOT NULL, -- 'cliente', 'asistente_ia', 'humano_andres'
    texto TEXT NOT NULL,
    tokens_usados INT DEFAULT 0,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mensajes_conversacion ON mensajes(conversacion_id, creado_en ASC);

-- --------------------------------------------------------
-- 6. CATÁLOGO DE SERVICIOS
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS servicios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    duracion_minutos INT NOT NULL,
    precio_base_cop NUMERIC(10, 2) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insertar servicios base de Andrés Díaz
INSERT INTO servicios (codigo, nombre, duracion_minutos, precio_base_cop, descripcion) 
VALUES 
    ('balayage_signature', 'Balayage Signature & Diseño de Color', 240, 180000.00, 'Técnica personalizada de degradado a mano alzada con baño de brillo y matiz.'),
    ('corte_styling', 'Corte de Tendencia & Styling', 60, 45000.00, 'Visagismo, lavado, corte técnico y acabado con brushing u ondas.'),
    ('terapia_reparacion', 'Terapia Nutritiva & Reparación', 75, 70000.00, 'Tratamiento intensivo de hidratación profunda, cauterización y brillo espejo.'),
    ('matiz_gloss', 'Mantenimiento de Tono & Brillo Gloss', 60, 65000.00, 'Renovación de color para neutralizar reflejos y recuperar luminosidad.')
ON CONFLICT (codigo) DO NOTHING;

-- --------------------------------------------------------
-- 7. CITAS AGENDADAS (VALIDACIÓN TRANSACCIONAL)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS citas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    servicio_id UUID NOT NULL REFERENCES servicios(id) ON DELETE RESTRICT,
    fecha_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    fecha_fin TIMESTAMP WITH TIME ZONE NOT NULL,
    estado VARCHAR(30) DEFAULT 'confirmada', -- 'confirmada', 'cancelada', 'reprogramada', 'completada'
    google_event_id VARCHAR(150),
    recordatorio_enviado BOOLEAN DEFAULT FALSE,
    notas TEXT,
    creada_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actualizada_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_citas_rango ON citas(fecha_inicio, fecha_fin);
CREATE INDEX IF NOT EXISTS idx_citas_cliente ON citas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_citas_estado ON citas(estado);
