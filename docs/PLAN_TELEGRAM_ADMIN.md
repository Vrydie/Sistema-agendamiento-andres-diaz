# 📱 PLAN DE IMPLEMENTACIÓN: CANAL DE TELEGRAM ADMIN (ANDRÉS PELUQUERÍA)
**Proyecto:** Sistema de Captura y Agendamiento Automático - Andrés Peluquería  
**Módulo:** Asistente de Gestión y Notificaciones para el Administrador (Telegram Admin Bot)  
**Versión:** 1.0.0 (Fase 4 - Operaciones y Control del Dueño)

---

## 🎯 1. VISIÓN GENERAL Y OBJETIVO DE NEGOCIO
El canal de WhatsApp atiende al **cliente final** con inteligencia artificial (Valentina). Sin embargo, Andrés (el dueño) no debe estar metido en los chats de WhatsApp revisando qué agendó la IA, ni debe depender de entrar manualmente a hojas de cálculo mientras está con las manos ocupadas cortando o tinturando cabello.

**Telegram actúa como la "Oficina de Bolsillo" de Andrés:**
1. **Push en Tiempo Real:** Cada vez que una clienta confirma una cita en WhatsApp, Andrés recibe una notificación instantánea con todos los datos y un enlace directo para abrir el chat del cliente si lo desea.
2. **Consulta Rápida de Agenda:** Andrés puede preguntarle a su bot en lenguaje natural o con comandos simples: *"¿Qué citas tengo hoy?"*, y recibe un resumen cronológico ordenado.
3. **Gestión Operativa sin Salir de Telegram:** Bloquear horarios de emergencia (almuerzo, compras de insumos, imprevistos) o cancelar citas.

---

## 🏗️ 2. ARQUITECTURA TÉCNICA (MODULAR & CLEAN)

```text
       [CLIENTE EN WHATSAPP]
                 │
                 ▼
          [DS-01_WebhookIn]
                 │
                 ▼
         [DS-02_AgentRouter] (Valentina IA)
                 │
                 ▼
          [T-02_CrearCita]
          ├──> 1. Inserta en PostgreSQL (citas)
          ├──> 2. Escribe en Google Sheets (AndresPDB)
          └──> 3. Dispara Notificación Push a Telegram (TG-01)
                                      │
                                      ▼
                        [TELEGRAM PRIVADO DE ANDRÉS]
                                      │
                        (Andrés consulta /agenda)
                                      ▼
                             [TG-02_ComandosAdmin]
                                      │
                           Consulta a PostgreSQL
                                      ▼
                        Responde lista del día a Andrés
```

---

## ⚙️ 3. ESPECIFICACIÓN DE FLUJOS EN N8N

### Flujo 1: `TG-01_NotificadorCitas` (Notificación Push Saliente)
- **Tipo:** Subflujo / Disparado al confirmar cita en `T-02_CrearCita`.
- **Nodo n8n:** `Telegram Node` (Operation: *Send Message*).
- **Formato del Mensaje:**
```text
🔔 ¡NUEVA CITA CONFIRMADA!

👤 Cliente: Carlos Gómez
💇 Servicio: Corte de Tendencia & Styling
💰 Valor: $45.000 COP
⏰ Horario: Lunes 12 de Octubre - 3:00 PM
📍 Sede: Cra 83 # 09

📱 WhatsApp del Cliente:
https://wa.me/573154899983
```
- **Botones Interactivos (Inline Keyboard):**
  - `[✅ Confirmar Llegada]`
  - `[❌ Cancelar Cita]`

---

### Flujo 2: `TG-02_ComandosAdmin` (Gestor Interactivo Entrante)
- **Disparador:** `Telegram Trigger` (Event: *Message Received*).
- **Filtro de Seguridad (Auth):**
  - Condición estricta: `{{ $json.message.chat.id }} == {{ $env.TELEGRAM_ADMIN_CHAT_ID }}`.
  - Si cualquier persona ajena le escribe al bot, es ignorada de inmediato con respuesta: *"Acceso restringido al administrador"*.
- **Comandos Soportados:**
  1. `/hoy` o `/agenda`:
     - Consulta a PostgreSQL:
       ```sql
       SELECT c.fecha_inicio, cl.nombre, cl.wa_id, s.nombre AS servicio, s.precio_base_cop
       FROM citas c
       JOIN clientes cl ON cl.id = c.cliente_id
       JOIN servicios s ON s.id = c.servicio_id
       WHERE DATE(c.fecha_inicio AT TIME ZONE 'America/Bogota') = CURRENT_DATE
         AND c.estado = 'confirmada'
       ORDER BY c.fecha_inicio ASC;
       ```
     - Formatea y responde la lista cronológica del día con total claridad.
  2. `/bloquear [hora_inicio] [hora_fin]`:
     - Inserta un bloqueo administrativo en la tabla de citas para que Valentina no asigne ese espacio.

---

## 🔒 4. SEGURIDAD Y PRIVACIDAD
1. **Token Protegido:** El `TELEGRAM_BOT_TOKEN` se almacena exclusivamente en variables de entorno o credenciales cifradas de n8n.
2. **Whitelist de Chat ID:** Únicamente el ID numérico de Telegram de Andrés puede interactuar con el bot. Nadie más en internet puede ver los datos de sus clientes.
3. **Costo Cero ($0):** La API de Telegram Bots es 100% gratuita, ilimitada y sin cobros por mensajes salientes.

---

## 💼 5. RETORNO DE INVERSIÓN (ROI) Y VALOR COMERCIAL B2B
Al presentarle esto a Andrés, este módulo transforma la solución de una "simple página web" a un **Sistema Integral de Gestión de Salón (SaaS Privado)**:

| Característica | Beneficio Real para Andrés | Impacto Económico |
|---|---|---|
| **Alerta Push Inmediata** | Andrés no tiene que estar pendiente de WhatsApp ni refrescar hojas de cálculo. | Cero interrupciones mientras atiende. |
| **Enlace Directo wa.me** | Con un solo toque en Telegram, Andrés le escribe a la clienta si hay retrasos. | Fidelización y trato personalizado VIP. |
| **Consulta `/hoy`** | Sabe exactamente cuántas citas y cuánto dinero proyecta ingresar ese día. | Control financiero y tranquilidad mental. |
| **Cero Apps Nuevas** | Andrés ya tiene Telegram en su teléfono, no debe aprender software complejo. | Adopción inmediata sin resistencia al cambio. |

---

## 📋 6. PASOS DE IMPLEMENTACIÓN (ROADMAP TÉCNICO)

1. **Fase 1: Creación del Bot en Telegram (3 minutos)**
   - Abrir `@BotFather` en Telegram.
   - Enviar `/newbot` ➡️ Nombre: `Andrés Peluquería Agenda` ➡️ Usuario: `AndresPeluqueriaBot`.
   - Guardar el `BOT_TOKEN`.
   - Obtener el `CHAT_ID` personal de Andrés escribiendo a `@userinfobot`.

2. **Fase 2: Conexión de Credenciales en n8n (2 minutos)**
   - Añadir la credencial `Telegram API` con el token en Railway n8n.

3. **Fase 3: Flujo `TG-01_NotificadorCitas` (5 minutos)**
   - Crear el subflujo que recibe los datos de la cita y envía el mensaje con formato markdown enriquecido a Andrés.
   - Conectar un llamado a `TG-01` al final de `T-02_CrearCita`.

4. **Fase 4: Flujo `TG-02_ComandosAdmin` (10 minutos)**
   - Configurar `Telegram Trigger`, filtro de seguridad `chat_id`, consulta Postgres del día y formateo de respuesta.

5. **Fase 5: Validación End-to-End**
   - Agendar cita desde WhatsApp y verificar que el celular de Andrés vibre en Telegram al mismo segundo.
