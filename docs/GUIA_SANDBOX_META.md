# 🧪 GUÍA DE CONFIGURACIÓN: SANDBOX DE WHATSAPP CLOUD API (META)
**Proyecto:** Sistema de Captura y Agendamiento - Andrés Peluquería  
**Objetivo:** Obtener un entorno de prueba oficial y gratuito con Meta for Developers para validar el bot sin costos ni riesgos de baneo.

---

## 📌 1. ¿Por qué usar el Sandbox oficial de Meta?
- **100% Gratuito:** Meta no cobra por mensajes en modo Sandbox/desarrollo ni por las primeras 1.000 conversaciones de servicio al mes.
- **Número de prueba asignado:** Meta provee un número virtual de prueba oficial (ej. `+1 555...`).
- **Seguridad total:** Protege el número comercial real de Andrés mientras realizamos pruebas de estrés y validamos el motor n8n.

---

## 🛠️ 2. Paso a Paso para Crear la App en Meta

### Paso 1: Ingreso a Meta for Developers
1. Ve a [developers.facebook.com](https://developers.facebook.com/).
2. Inicia sesión con tu cuenta personal de Facebook.
3. Si no tienes perfil de desarrollador, pulsa en **"Comenzar"** (*Get Started*) y acepta los términos.

### Paso 2: Crear la Aplicación
1. Haz clic en el botón verde **"Crear app"** (*Create App*).
2. Selecciona:
   - Caso de uso: **"Otro"** (*Other*) ➡️ *Siguiente*.
   - Tipo de app: **"Negocio"** (*Business*) ➡️ *Siguiente*.
3. Completa los datos:
   - **Nombre de la app:** `Sistema-Agendamiento-Andres-Diaz`
   - **Correo de contacto:** Tu correo electrónico.
   - **Cuenta comercial:** Déjala en *"Ninguna seleccionada por ahora"* o selecciona tu Business Manager si ya tienes uno.
4. Clic en **"Crear app"**.

### Paso 3: Agregar el Producto WhatsApp
1. En el panel de productos de tu app, busca la tarjeta **WhatsApp**.
2. Haz clic en **"Configurar"** (*Set up*).
3. Serás redirigido a la sección **"Inicio de la API"** (*API Setup*).

---

## 🔑 3. Las Credenciales Clave que Extraeremos

En la pantalla **Inicio de la API** (*API Setup*), copia y guarda los siguientes datos:

| Variable | Descripción | Ubicación en Meta |
|---|---|---|
| `WHATSAPP_TOKEN` | Token de acceso temporal (dura 24 horas para pruebas). | Campo *"Token de acceso temporal"* |
| `WHATSAPP_PHONE_NUMBER_ID` | Identificador del número de teléfono (15 dígitos aprox). | Campo *"Identificador de número de teléfono"* |
| `WABA_ID` | Identificador de la cuenta de WhatsApp Business. | Campo *"Identificador de la cuenta de WhatsApp Business"* |
| `TEST_PHONE_NUMBER` | Número de prueba asignado por Meta (ej: `+1 555...`). | Campo *"Desde (From)"* |

---

## 📲 4. Registrar tu Celular para Pruebas

Debido a que la app está en modo desarrollo, Meta solo permite enviar mensajes a números autorizados:
1. En el campo **"Para" (*To*)**, selecciona **"Administrar lista de números de teléfono"**.
2. Añade tu número de celular personal con código de país (ej. `+57` para Colombia).
3. Meta te enviará un código de verificación por WhatsApp.
4. Ingrésalo en la pantalla. ¡Listo! Ya estás autorizado para recibir y enviar mensajes con el bot.

---

## 🌐 5. Configuración del Webhook en n8n (Próximo Paso)

Meta necesita saber a dónde enviar los mensajes que tú le escribas al bot:
1. En el menú lateral de WhatsApp en Meta, haz clic en **"Configuración"** (*Configuration*).
2. En la sección **Webhook**:
   - **URL de devolución de llamada:** `https://<TU-TUNEL-O-N8N>/webhook/whatsapp`
   - **Identificador de verificación (Verify Token):** Un token secreto definido por nosotros (ej. `AndresPeluqueriaSegura2026`).
3. En los campos de suscripción de Webhook, marcar:
   - `messages` (Obligatorio para recibir texto y eventos de chat).
