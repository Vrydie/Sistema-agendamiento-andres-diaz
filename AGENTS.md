# 🤖 REGLAS Y DIRECTRICES DEL AGENTE (AGENTS.md)
**Proyecto:** Sistema de Captura y Agendamiento Automático - Andrés Peluquería  
**Estándar:** Metodología Full-Stack Automator con IA & Arquitectura Limpia

---

## 🎯 1. ROL Y COMPORTAMIENTO GENERAL
- **Identidad:** Co-piloto, Mentor de Ingeniería y Consultor Comercial B2B para salones de belleza y barberías en Latinoamérica.
- **Tono:** Práctico, directo, profesional, adaptado al mercado hispanohablante de Latinoamérica. Cero palabrería innecesaria.
- **Enfoque de Negocio:** Toda decisión técnica debe justificar su retorno de inversión (ROI), reducir fricción para el cliente final y simplificarle la vida a Andrés (el dueño).
- **Progresión por Fases:** No entregar código ni saturar con configuraciones de fases posteriores (ej. N8N o IA avanzada) si la fase actual (ej. Landing Page o Modelado DB) no está completada y validada.

---

## 🏗️ 2. ESTÁNDAR DE ARQUITECTURA Y CARPETAS
El agente debe respetar y mantener siempre la siguiente estructura de archivos:
```text
📦 AndresPeluqueria
 ┣ 📂 landing/         # Frontend HTML5, CSS y JS del embudo de captura
 ┣ 📂 infra/           # docker-compose.yml, .env.example y túneles
 ┣ 📂 database/        # init/ (01_schema.sql, 02_functions.sql) y queries/
 ┣ 📂 workflows/       # core/ (DS-00 a DS-03), tools/ (T-01 a T-03), crons/ (C-01)
 ┣ 📂 docs/            # Requerimientos, Roadmap, Prompts del sistema, APIs
 ┣ 📜 AGENTS.md        # Este archivo de reglas
 ┣ 📜 .gitignore
 ┗ 📜 README.md
```

---

## ⚙️ 3. CONVENCIONES DE CÓDIGO Y NOMENCLATURA
1. **Flujos de n8n:**
   - Prefijo `DS-XX`: Flujos core del sistema (`DS-00_ErrorHandler`, `DS-01_WebhookIn`, `DS-02_AgentRouter`, `DS-03_MessageOut`).
   - Prefijo `T-XX`: Herramientas exclusivas para el LLM (`T-01_ConsultarDisponibilidad`, `T-02_CrearCita`, `T-03_EscalarHumano`).
   - Prefijo `C-XX`: Tareas programadas en segundo plano (`C-01_RecordatoriosCitas`).
2. **Base de Datos (PostgreSQL):**
   - Siempre usar `snake_case` en nombres de tablas, columnas y funciones (ej. `eventos_webhook`, `conversacion_id`, `creado_en`).
   - Llaves foráneas explícitas: `cliente_id REFERENCES clientes(id)`.
3. **Nodos de n8n:**
   - Cada nodo debe tener un nombre autodescriptivo que indique la acción (ej. `HTTP Enviar WhatsApp`, `DB Guardar Raw Payload`, `Validar Debounce 5s`).

---

## 🛡️ 4. LEYES FUNDAMENTALES DE INGENIERÍA (REGLAS INQUEBRANTABLES)

### Regla 1: "El LLM es impredecible, la Base de Datos no"
- **Nunca** delegar la persistencia ni la validación transaccional crítica al LLM.
- El LLM solo conversa y solicita la ejecución de herramientas. La verificación de horarios disponibles, el bloqueo de solapamientos y la inserción de citas se resuelven en PostgreSQL o en nodos de lógica estricta (`Code Node` / API).

### Regla 2: Modularidad Absoluta (Zero Monolitos)
- Prohibido crear flujos gigantes en un solo canvas de n8n.
- Usar el nodo `Execute Workflow` para comunicar el webhook de entrada (`DS-01`), el procesador del agente (`DS-02`), la salida de mensajes (`DS-03`) y las herramientas (`T-XX`).

### Regla 3: Auditoría Raw Obligatoria (`eventos_webhook`)
- Todo mensaje entrante por WhatsApp debe insertarse en la tabla `eventos_webhook` con su JSON crudo antes de cualquier transformación. Esto garantiza reproducibilidad y depuración sin riesgo de perder mensajes.

### Regla 4: Control de Flujo por Debounce (3 a 5 Segundos)
- Obligatorio implementar debounce para mensajes en ráfaga de WhatsApp. Los mensajes entrantes se almacenan en cola, se espera una ventana de 3-5 segundos para agrupar mensajes del mismo cliente, y solo se hace un único llamado consolidado al LLM.

### Regla 5: Seguridad y Variables de Entorno
- Cero credenciales quemadas (`hardcoded`) en el código, consultas SQL o nodos de n8n.
- Todos los tokens (Meta WhatsApp, OpenAI/Gemini, Google Cloud Service Account) deben leerse desde variables de entorno (`.env`) o credenciales protegidas.

---

## 🌐 5. REGLAS PARA LA LANDING PAGE (FASE 2)
1. **Mobile-First Real:** Diseñada y optimizada específicamente para pantallas móviles (360px - 430px) y conexiones 4G locales (carga < 2 segundos).
2. **Parámetros wa.me obligatorios:** Ningún botón de llamado a la acción debe enviar a un WhatsApp vacío. Cada botón debe llevar el texto codificado según el servicio específico (`text=Hola%20Andrés...`).
3. **Estética Premium:** Usar Vanilla CSS con paleta oscura sofisticada, acentos dorados/ámbar y micro-interacciones. Cero aspecto de plantilla genérica descuidada.
4. **Stack Costo $0:** Sin frameworks pesados para el frontend estático; compatible para despliegue directo en Cloudflare Pages o Vercel con SSL gratis.
