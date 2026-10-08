# Metodología y Estructura de Proyectos de Automatización con IA

Esta guía define el estándar de trabajo para estructurar, planear y ejecutar proyectos de automatización avanzados que involucren agentes de inteligencia artificial (LLMs), bases de datos y orquestadores como n8n. Está diseñada para ser ejecutada por una sola persona (Full-Stack Automator), garantizando orden, escalabilidad y mínima tasa de errores.

---

## 1. Roadmap del Proyecto (Fases de Ejecución)

Para evitar retrabajos y errores de arquitectura, todo proyecto debe seguir estas fases en estricto orden:

### Fase 1: Levantamiento de Requerimientos y Diseño
- **Definir el objetivo central:** ¿Qué problema resuelve el bot/automatización? (ej. Ventas, Soporte, Agendamiento).
- **Mapeo de integraciones:** Listar APIs necesarias (WhatsApp/YCloud, Shopify, Google Sheets, pasarelas de pago).
- **Diseño del flujo conversacional (Happy Path):** Documentar cómo debe ser la conversación ideal y cuáles son los límites del bot.
- **Definición de Herramientas (Tools):** ¿Qué acciones concretas debe poder ejecutar la IA? (ej. consultar_estado, crear_pedido, consultar_cobertura).

### Fase 2: Modelado de Datos y Arquitectura
- **Diseño de la Base de Datos:** Crear el esquema Entidad-Relación. Todo bot avanzado necesita persistencia (PostgreSQL recomendado) para:
  - Guardar el estado de las conversaciones (memoria).
  - Gestionar colas de mensajes y *debouncing* (evitar respuestas duplicadas).
  - Almacenar configuración centralizada (tokens, reglas de negocio).
- **Definición de Variables de Entorno:** Identificar qué secretos se manejarán y cómo se inyectarán en la infraestructura.

### Fase 3: Infraestructura y Entorno (Dockerización)
- **Configuración de `docker-compose.yml`:** Levantar n8n, PostgreSQL y túneles (como Cloudflare) en un entorno local que sea idéntico al de producción.
- **Scripts de inicialización:** Ejecutar los scripts SQL que construyen las tablas de la base de datos antes de tocar n8n.

### Fase 4: Desarrollo de Flujos Base (Core Workflows)
Nunca construir todo en un solo flujo. Dividir en micro-servicios:
- **Flujo de Entrada (Webhook):** Recibe, normaliza, valida la seguridad (firmas) y guarda en base de datos.
- **Flujo de Salida (Transporte):** Un único flujo responsable de enviar mensajes a la API final. Maneja errores de envío y formateo de burbujas.
- **Flujo Manejador de Errores (Error Handler):** Atrapa caídas globales y alerta al administrador (ej. por Telegram).

### Fase 5: Desarrollo del Agente y Herramientas (Tools)
- **Construcción del Agente:** Configurar el nodo LangChain / AI Agent. Conectar la memoria de Postgres.
- **Creación de Herramientas (Sub-flujos):** Cada tool (consultar inventario, crear link de pago) debe ser un sub-flujo independiente. 
- **Pruebas aisladas:** Probar cada herramienta inyectando datos falsos antes de conectarla al agente.

### Fase 6: Pruebas End-to-End y Despliegue
- **Testing:** Simular webhooks. Revisar los logs detallados (`eventos_webhook`, `mensajes`).
- **Paso a Producción:** Despliegue en VPS (DigitalOcean, AWS, etc.) usando los mismos archivos Docker.

---

## 2. Estructura de Directorios del Repositorio

Un proyecto profesional no debe depender de exportaciones manuales sueltas. Esta es la estructura de carpetas estándar:

```text
📦 NombreDelProyecto
 ┣ 📂 infra/                    # Todo lo relacionado a levantar el sistema
 ┃ ┣ 📜 docker-compose.yml      # Definición de contenedores (n8n, db, túnel)
 ┃ ┣ 📜 .env                    # (IGNORADO EN GIT) Credenciales y variables
 ┃ ┗ 📜 Dockerfile              # (Opcional) Si se requiere extender n8n con dependencias (ej. Python)
 ┃
 ┣ 📂 database/                 # Persistencia y esquemas
 ┃ ┣ 📂 init/                   # Scripts que corren automáticamente al crear el contenedor BD
 ┃ ┃ ┣ 📜 01_schema.sql         # Tablas, índices y enums
 ┃ ┃ ┗ 📜 02_functions.sql      # Procedimientos almacenados (ej. ycloud_ingresar)
 ┃ ┣ 📂 migrations/             # Scripts para alteraciones futuras en la BD
 ┃ ┗ 📜 queries.sql             # Consultas útiles o de mantenimiento
 ┃
 ┣ 📂 workflows/                # Código fuente de las automatizaciones (Respaldos JSON)
 ┃ ┣ 📂 core/                   # Flujos principales del sistema
 ┃ ┃ ┣ 📜 DS-00_ErrorHandler.json
 ┃ ┃ ┣ 📜 DS-01_WebhookIn.json
 ┃ ┃ ┣ 📜 DS-02_AgentRouter.json
 ┃ ┃ ┗ 📜 DS-03_MessageOut.json
 ┃ ┣ 📂 tools/                  # Herramientas exclusivas para el agente LLM
 ┃ ┃ ┣ 📜 T01_CrearPedido.json
 ┃ ┃ ┣ 📜 T02_ConsultarEstado.json
 ┃ ┃ ┗ 📜 T03_EscalarHumano.json
 ┃ ┗ 📂 crons/                  # Tareas programadas (Limpieza, reportes)
 ┃   ┗ 📜 C01_LimpiarMemoria.json
 ┃
 ┣ 📂 docs/                     # Documentación esencial
 ┃ ┣ 📜 ROADMAP.md              # Estado actual del proyecto y tareas pendientes
 ┃ ┣ 📜 PROMPT_SYSTEM.md        # Respaldo del comportamiento y reglas del Agente
 ┃ ┗ 📜 API_REFERENCES.md       # Ejemplos de requests de APIs de terceros (YCloud, Shopify)
 ┃
 ┣ 📜 .gitignore                # Evitar subir el .env y volúmenes de datos
 ┗ 📜 README.md                 # Instrucciones para levantar el proyecto desde cero
```

---

## 3. Convenciones de Nomenclatura

Para mantener la cordura cuando el proyecto crezca:

### Archivos de Flujos (Workflows)
Usar prefijos estructurados:
- **`DS-XX`** (Direct Service / Core): Flujos base. Ej: `DS-01_Webhook_Entrada`
- **`T-XX`** (Tool): Herramientas llamadas por la IA. Ej: `T-01_Consultar_Cobertura`
- **`C-XX`** (Cron): Procesos en segundo plano. Ej: `C-01_Limpieza_DB`

### Nodos en n8n
- Nodos lógicos deben ser descriptivos: `Es entrada`, `Guardar salida 1`, `Debounce`.
- Nodos HTTP o Base de Datos deben especificar la acción: `HTTP enviar mensaje`, `Actualizar estado DB`.

### Base de Datos
- Usar `snake_case` para todo (tablas, columnas, funciones). Ej: `creado_en`, `conversacion_id`.
- Nombrar llaves foráneas indicando claramente la relación: `cliente_id` -> `clientes(id)`.

---

## 4. Prácticas Clave (Lecciones Aprendidas)

1. **El Agente es impredecible, la Base de Datos no:**
   Nunca confíes en que el LLM guarde o gestione la lógica crítica del negocio. El LLM solo "habla" y "pide usar herramientas". Toda la lógica transaccional (ej. revisar si un agente humano está ocupado, o validar firmas de webhooks) debe hacerse en Postgres o en nodos de código (`Code Node`).

2. **Modularidad Absoluta (Call Workflow):**
   Usa el nodo `Execute Workflow`. Si cambias la lógica de envío de WhatsApp, solo modificas el flujo `DS-03`. Si cambias la IA, solo tocas el `DS-02`. No repitas código ni configuraciones de envío en distintos lugares.

3. **Guarda TODO lo que entra y sale:**
   Ten una tabla como `eventos_webhook` donde inyectes el JSON crudo (raw payload) de TODO lo que llega. Si algo falla o el LLM se vuelve loco, puedes ir a esa tabla, sacar el JSON y simular el webhook localmente para depurar sin necesidad de enviar mensajes reales.

4. **Variables de Entorno para Todo lo Sensible:**
   Ningún Token (YCloud, OpenAI, Meta) ni URL de base de datos debe ir quemado en un nodo de n8n. Utiliza nodos que lean la base de datos de configuraciones o utiliza las *Credentials* nativas de n8n amarradas al `.env`.

5. **El control de flujo por Debounce:**
   Los usuarios en WhatsApp mandan 5 mensajes seguidos (ej: "Hola", "Quiero info", "del producto", "porfa", "gracias"). 
   El sistema debe ingresar los mensajes a la base de datos, esperar 3-5 segundos (`Wait Node`), y luego agruparlos antes de mandarlos al Agente. Esto ahorra dinero en tokens y mejora considerablemente la experiencia del usuario final.
