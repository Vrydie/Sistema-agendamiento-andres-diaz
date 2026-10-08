# 🚀 GUÍA DE DESPLIEGUE EN RENDER (N8N + POSTGRESQL 24/7)
**Proyecto:** Sistema de Captura y Agendamiento - Andrés Peluquería  
**Objetivo:** Tener n8n corriendo en la nube con URL HTTPS permanente y gratuita, sin túneles temporales ni depender de tu computador.

---

## 📌 ¿Por qué Render?
1. **URL Fija Permanente:** Te asigna un dominio público con certificado SSL gratis (ej. `https://n8n-andres.onrender.com`).
2. **Cero Túneles:** Conectas el Webhook de Meta una sola vez y nunca más lo vuelves a tocar.
3. **Costo $0:** Capa gratuita para Web Services y base de datos.

---

## 🛠️ PASO A PASO: DESPLIEGUE EN RENDER

### Paso 1: Crear cuenta en Render
1. Ve a 👉 [render.com](https://render.com/).
2. Haz clic en **"Sign In"** o **"Get Started"** y selecciona **"Sign in with GitHub"** (así queda vinculado directamente a tu cuenta `Vrydie`).

---

### Paso 2: Crear la Base de Datos PostgreSQL
Antes de levantar n8n, necesitamos la base de datos relacional:
1. En el panel de Render, haz clic en el botón superior **"New +"** ➡️ selecciona **"PostgreSQL"**.
2. Configura los siguientes campos:
   - **Name:** `postgres-andres-peluqueria`
   - **Database:** `andres_peluqueria`
   - **User:** `andres_admin`
   - **Region:** Selecciona la más cercana (ej: *Ohio (US East)* o *Oregon (US West)*).
   - **PostgreSQL Version:** 16 (la más reciente).
   - **Instance Type:** Selecciona **Free** ($0/month).
3. Haz clic en **"Create Database"**.
4. Render tardará unos 60 segundos en crearla.
5. Cuando esté lista, busca la sección **"Connections"** y copia:
   - El **Internal Database URL** (para conectar n8n directamente).
   - O los valores individuales: *Hostname*, *Port*, *Database*, *Username* y *Password*.

---

### Paso 3: Desplegar n8n como Web Service
1. En el panel de Render, haz clic nuevamente en **"New +"** ➡️ selecciona **"Web Service"**.
2. En la opción de fuente, selecciona **"Deploy an existing image"** (Desplegar imagen existente).
3. En el campo de imagen Docker, pega exactamente:
   ```text
   docker.n8n.io/n8nio/n8n:latest
   ```
4. Haz clic en **"Next"** o continuar.
5. Configura los datos básicos:
   - **Name:** `n8n-andres-peluqueria` (esto definirá tu URL: `https://n8n-andres-peluqueria.onrender.com`).
   - **Region:** Selecciona **la misma región** donde creaste la base de datos PostgreSQL.
   - **Instance Type:** Selecciona **Free** ($0/month).
6. Desplázate hacia abajo hasta la sección **"Environment Variables"** (Variables de Entorno) y agrega las siguientes:

| Variable | Valor | Explicación |
|---|---|---|
| `N8N_PORT` | `5678` | Puerto interno de n8n |
| `PORT` | `5678` | Puerto que detecta Render |
| `N8N_PROTOCOL` | `https` | Protocolo seguro |
| `GENERIC_TIMEZONE` | `America/Bogota` | Zona horaria de Colombia |
| `TZ` | `America/Bogota` | Zona horaria del contenedor |
| `N8N_ENCRYPTION_KEY` | `AndresPeluqueriaSecureKey2026!` | Clave de cifrado de credenciales |
| `DB_TYPE` | `postgresdb` | Conexión a Postgres |
| `DB_POSTGRESDB_HOST` | *(El Hostname de tu Postgres en Render)* | Conexión interna |
| `DB_POSTGRESDB_PORT` | `5432` | Puerto estándar |
| `DB_POSTGRESDB_DATABASE` | `andres_peluqueria` | Nombre de la DB |
| `DB_POSTGRESDB_USER` | `andres_admin` | Usuario DB |
| `DB_POSTGRESDB_PASSWORD` | *(El Password de tu Postgres en Render)* | Contraseña DB |
| `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED` | `false` | Permitir SSL en la nube |
| `WEBHOOK_URL` | `https://n8n-andres-peluqueria.onrender.com/` | Tu URL de Render |
| `N8N_HOST` | `n8n-andres-peluqueria.onrender.com` | Tu subdominio en Render |

7. Haz clic en **"Create Web Service"**.

---

### Paso 4: ¡Tu n8n en Vivo y Permanente!
1. Render comenzará a descargar la imagen y configurar el servicio (tarda ~2 a 3 minutos).
2. Cuando el estado cambie a **"Live"**, haz clic en el enlace superior de tu servicio (ej. `https://n8n-andres-peluqueria.onrender.com`).
3. Te pedirá crear tu usuario y contraseña de administrador de n8n por primera vez.
4. **¡Listo!** Ya tienes n8n corriendo 24/7 en la nube con una URL que nunca va a cambiar.

---

### 🔗 Tu Webhook Definitivo para Meta WhatsApp:

Una vez activo, tu URL de Webhook para configurar en Meta for Developers será:
```text
https://n8n-andres-peluqueria.onrender.com/webhook/whatsapp
```
Con el Verify Token que dejamos en el código:
```text
AndresPeluqueria2026
```
*(¡Y nunca más tendrás que preocuparte por túneles ni reconexiones!)*
