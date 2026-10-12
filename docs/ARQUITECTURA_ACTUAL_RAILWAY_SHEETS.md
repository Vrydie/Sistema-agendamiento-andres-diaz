# 🏗️ ARQUITECTURA DE PRODUCCIÓN (RAILWAY, WHATSAPP & GOOGLE SHEETS)
**Proyecto:** Sistema de Captura y Agendamiento Automático - Andrés Peluquería  
**Estado Actual:** MVP Operativo y Validado en Producción  
**Fecha de Validación:** 12 de Octubre de 2026

---

## 🌐 1. INFRAESTRUCTURA EN LA NUBE (RAILWAY)
- **Servicio n8n:**  
  URL: `https://primary-production-43a45.up.railway.app`  
  Versión: `n8n v2.42.6 (Self Hosted)`  
  Características: Servidor dinámico en Railway con SSL automático y soporte de SSE (sin caídas de "Offline").
- **Base de Datos PostgreSQL (Interna en Railway):**  
  Host Interno: `postgres.railway.internal:5432`  
  Base de Datos: `railway`  
  Usuario: `postgres`  
  Tablas: `clientes`, `conversaciones`, `mensajes`, `citas`, `servicios`, `eventos_webhook`, `cola_mensajes_debounce`.

---

## 📱 2. INTEGRACIÓN OFICIAL META CLOUD API (WHATSAPP)
- **Número Oficial del Salón:** `+57 310 8484221`
- **Display Name en WhatsApp:** `PAndres`
- **Phone Number ID:** `1359724723893315`
- **WABA ID (WhatsApp Business Account):** `1891160245592571`
- **Webhook Endpoint Verificado:**  
  `https://primary-production-43a45.up.railway.app/webhook/whatsapp`
- **Verify Token:** `AndresPeluqueria2026`
- **Modelo de Cobro:** Meta Oficial directo (1.000 conversaciones gratuitas de atención iniciadas por clientes cada mes). Cero costos fijos.

---

## 📊 3. CRM EN TIEMPO REAL: GOOGLE SHEETS API
- **Proyecto en Google Cloud Console:** `Andres-Peluqueria`
- **APIs Habilitadas:**
  - Google Sheets API v4
  - Google Drive API v3
- **Autenticación:** OAuth2 Client ID y Client Secret con refresh token persistente en n8n.
- **Hoja de Cálculo:** `AndresPDB` (Hoja 1)
- **Columnas Configuradas:**
  | Columna | Nombre | Tipo / Origen |
  |---|---|---|
  | **A** | Fecha Registro | Generada en n8n (`$now` hora Colombia) |
  | **B** | Nombre Cliente | Extraído por IA (`$fromAI`) |
  | **C** | WhatsApp | Extraído del remitente real (`wa_id`) |
  | **D** | Servicio | Extraído por IA y cruzado en PostgreSQL |
  | **E** | Fecha Cita | Extraído por IA (`$fromAI`) con formato Bogotá |
  | **F** | Precio COP | Obtenido de tabla `servicios` en Postgres |
  | **G** | Estado | Fijo: `Confirmada` |

---

## 🤖 4. ASISTENTE VIRTUAL: VALENTINA (GEMINI)
- **Modelo:** Google Gemini (Google AI Studio) integrado en n8n LangChain Agent.
- **Identidad:** Valentina, recepcionista virtual de Andrés Díaz Peluquería (Cra 83 # 09).
- **Herramientas Conectadas:**
  - `agendar_cita` (apunta a `T-02_CrearCita`): Guarda en base de datos y agrega fila a Google Sheets cuando el cliente confirma nombre, servicio y fecha/hora.
- **Control de Mensajes en Ráfaga:** Debounce de 4 segundos en PostgreSQL para consolidar mensajes antes de llamar al LLM.
