# 📋 DOCUMENTO DE LEVANTAMIENTO DE REQUERIMIENTOS
**Proyecto:** Sistema de Captura y Agendamiento Inteligente por WhatsApp con IA  
**Cliente Piloto:** Andrés Peluquería  
**Versión:** 1.0 (Fase MVP - Costo $0)  
**Fecha:** 2026-10-08  
**Autores:** Equipo de Ingeniería & Consultoría  

---

## 1. 🎯 OBJETIVOS DEL SISTEMA

### 1.1 Objetivo General
Automatizar el 100% de la recepción, atención de dudas frecuentes y agendamiento de citas de Andrés Peluquería mediante una Landing Page persuasiva y un agente de IA en WhatsApp conectado en tiempo real con Google Calendar, operando 24/7 sin costo inicial de infraestructura.

### 1.2 Objetivos Específicos
1. **Captura:** Redirigir el tráfico de redes sociales y búsquedas a una Landing Page optimizada para móviles que pre-califique el servicio que busca el cliente.
2. **Atención Inmediata:** Responder mensajes de WhatsApp en menos de 5 segundos con tono humano, empático y adaptado a la jerga local.
3. **Agendamiento Sin Fricción:** Consultar disponibilidad en Google Calendar, proponer huecos libres y registrar la cita sin solapamientos (evitar doble reserva).
4. **Rescate & Reducción de No-Shows:** Dejar las bases listas para enviar recordatorios automáticos 2 horas antes de la cita.
5. **Escape Humano:** Permitir que Andrés o su equipo tomen el control del chat pausando el bot al detectar inconformidad o solicitud explícita de hablar con una persona.

---

## 2. 👥 ACTORES DEL SISTEMA

| Actor | Descripción | Canal Principal |
|---|---|---|
| **Cliente Final** | Usuario que busca cortarse el pelo, barba o servicio estético. | Landing Page / WhatsApp |
| **Andrés / Barbero** | Dueño del negocio que atiende las citas y supervisa la agenda. | Google Calendar / WhatsApp |
| **Agente IA (Bot)** | Sistema conversacional inteligente orquestado por N8N. | API WhatsApp / Backend |
| **Administrador Técnico** | Equipo de ingeniería (Ustedes) que monitorea errores y métricas. | N8N / Consolas Cloud |

---

## 3. ⚙️ REQUERIMIENTOS FUNCIONALES (RF)

### Módulo A: Landing Page (Embudo de Captura)
- **RF-01 (Diseño Mobile-First):** La web debe cargar en menos de 2 segundos en redes 4G móviles.
- **RF-02 (Catálogo Dinámico de Servicios):** Debe presentar los servicios principales (Corte, Barba, Combo, Colorimetría/Tratamientos) con precio y duración aproximada.
- **RF-03 (Parámetros Dinámicos WhatsApp):** Cada botón CTA debe generar un enlace `wa.me/` con un parámetro `text` que identifique el servicio de origen.
- **RF-04 (Indicador de Estado en Vivo):** La web debe indicar dinámicamente si el local se encuentra abierto o cerrado según la hora del cliente.
- **RF-05 (Prueba Social y Geolocalización):** Debe incluir botón de "Cómo llegar" enlazado a Google Maps y fotos reales del establecimiento.

### Módulo B: Agente de IA Conversacional (N8N + LLM)
- **RF-06 (Detección de Intención Inicial):** Si el mensaje proviene con texto de la Landing, la IA saluda reconociendo el servicio solicitado directamente.
- **RF-07 (Memoria Contextual a Corto Plazo):** El bot debe recordar los últimos 6 a 10 mensajes del cliente para no repetir preguntas absurdas.
- **RF-08 (Manejo de FAQs sin Agendar):** Debe responder dudas sobre precios, métodos de pago (efectivo, Nequi, Daviplata, transferencias), dirección y parqueadero sin forzar el agendamiento.
- **RF-09 (Function / Tool Calling Estricto):** La IA solo interactúa con el calendario mediante funciones predefinidas (`consultar_disponibilidad`, `crear_cita`, `cancelar_cita`).
- **RF-10 (Tono y Personalidad):** Tono respetuoso pero cercano, usando modismos locales medidos (ej. *"¡Hola! Con mucho gusto te ayudamos con tu corte en Andrés Peluquería"*).

### Módulo C: Gestión de Agenda (Google Calendar API)
- **RF-11 (Consulta de Bloques Libres):** El sistema debe consultar eventos en Google Calendar dentro del horario comercial (ej. 9:00 AM a 8:00 PM).
- **RF-12 (Bloqueo de Solapamientos):** No se pueden registrar citas en franjas donde ya exista un evento creado, considerando la duración estimada del servicio (ej. 40 min corte, 60 min combo).
- **RF-13 (Creación del Evento):** Al confirmar, el evento debe crearse con título: `[Cita] Nombre Cliente - Servicio` y en la descripción: `Teléfono: +57... / Origen: Bot IA`.

### Módulo D: Supervisión y Escape Humano
- **RF-14 (Activación de Pausa):** Si el cliente escribe palabras clave como *"hablar con una persona"*, *"quiero hablar con Andrés"* o el bot no comprende tras 2 intentos, el bot se silencia y notifica al dueño.
- **RF-15 (Reanudación):** El dueño puede reactivar el bot con un comando simple o tras un tiempo de inactividad (ej. 4 horas).

---

## 4. 🛡️ REQUERIMIENTOS NO FUNCIONALES (RNF)

- **RNF-01 (Costo $0 en Fase MVP):** Todas las herramientas y tiers utilizados en el desarrollo y primeras 100 citas deben operar en capas 100% gratuitas.
- **RNF-02 (Latencia de Respuesta):** El tiempo total entre el envío del mensaje del cliente en WhatsApp y la respuesta del bot no debe superar los 5 segundos.
- **RNF-03 (Seguridad de API Keys):** Ninguna clave secreta (OpenAI, Google Cloud, Meta) debe estar expuesta en el frontend ni en repositorios públicos.
- **RNF-04 (Disponibilidad / Uptime):** La landing debe tener 99.9% de uptime (respaldada en edge network tipo Vercel o Cloudflare Pages).
- **RNF-05 (Privacidad de Datos):** Solo se almacenará el nombre y teléfono del cliente para fines exclusivos del servicio y recordatorio de citas.

---

## 5. ⚠️ CASOS BORDE Y REGLAS DE NEGOCIO (EDGE CASES)

1. **Cliente pide cita en el pasado o fuera de horario:** El bot debe rechazar educadamente la hora y ofrecer las alternativas válidas más cercanas.
2. **Cliente no da su nombre:** El bot debe insistir amablemente en el nombre antes de crear el evento en el calendario.
3. **El cliente pide agendar 2 servicios a la vez (Corte + Barba):** El bot debe sumar las duraciones (ej. 45 min + 30 min = 75 min) para buscar un bloque continuo disponible.
4. **Respuestas de audio:** En el MVP, el bot responderá educadamente: *"Por ahora solo puedo leer texto, por favor escríbeme tu mensaje para agendarte rápido"*. (En Fase v2 se añade Whisper para transcribir audios).
