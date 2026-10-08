# 💈 PLAN Y DOCUMENTACIÓN TÉCNICA: LANDING PAGE DE ALTA CONVERSIÓN
**Proyecto:** Sistema de Captura y Agendamiento Automático - Andrés Peluquería  
**Fase Actual:** Fase 2 - Landing Page & Embudo a WhatsApp  
**Objetivo Comercial:** Convertir visitas locales en citas efectivas agendadas por el agente de IA en WhatsApp, eliminando la fricción y pre-clasificando el servicio deseado.

---

## 🎯 1. Objetivo y Filosofía del Embudo

El 90% o más de las visitas a una peluquería/barbería local provienen desde un **dispositivo móvil** (tráfico de Instagram, Google Maps, TikTok o referidos).

Por tanto, la Landing Page **no es un folleto estático**, sino un **embudo de captura directo**:
1. El usuario entra buscando solucionar una necesidad (corte, cambio de look, arreglo de barba).
2. Ve autoridad, estilo, precios claros y horarios disponibles.
3. Al dar clic a cualquier CTA (Llamado a la acción), es redirigido a WhatsApp con un **mensaje contextualizado** para que el bot de N8N sepa de inmediato qué servicio quiere y comience el flujo de agendamiento sin rodeos.

---

## 🏗️ 2. Arquitectura de Secciones (Mobile-First)

| # | Sección | Propósito / Elementos Clave | CTA / Interacción |
|---|---|---|---|
| **1** | **Top Bar / Header** | Logo, dirección resumida, estado en vivo (*"Abierto hoy hasta las 8:00 PM"*). | Botón flotante o fijo: *"Agendar Cita"* |
| **2** | **Hero Section** | Título de impacto (Dolor + Beneficio), propuesta de valor, badges de confianza (*+1.500 clientes satisfechos*). | Botón principal magnético: *"Reservar Cita por WhatsApp"* |
| **3** | **Servicios & Tarifas** | Tarjetas claras con nombre, duración estimada, precio y descripción corta. | Botón por servicio: *"Agendar este servicio"* (pre-llena texto para N8N) |
| **4** | **El Experto / La Experiencia** | Foto de Andrés / equipo, ambiente del local (café de cortesía, sillones confortables, higiene certificada). | Genera confianza y cercanía |
| **5** | **Galería de Trabajos (Showcase)** | Muestras de cortes/estilos recientes con estilo editorial moderno. | Inspira el estilo deseado |
| **6** | **Ubicación & Horarios** | Mapa interactivo, indicaciones de llegada (parqueadero cercano, puntos de referencia), horarios semanales. | Botón *"Cómo llegar"* (Google Maps) |
| **7** | **Preguntas Frecuentes (FAQ)** | Respuestas a objeciones comunes: medios de pago, anticipación requerida, cancelaciones. | Desplegables rápidos (Acordeón) |
| **8** | **Footer** | Redes sociales, contacto directo y copyright. | Enlace directo a WhatsApp |

---

## 📲 3. Estrategia de Enlace Dinámico a WhatsApp (`wa.me`)

Para que el agente de IA en N8N funcione con máxima precisión, los botones de la landing inyectarán la intención de compra mediante URL parameters:

- **Estructura base:**
  `https://wa.me/<NUMERO_TELEFONO>?text=<MENSAJE_CODIFICADO>`
- **Ejemplos por intención:**
  - *Hero General:* `https://wa.me/57XXXXXXXXXX?text=Hola%20Andrés,%20quiero%20agendar%20una%20cita.`
  - *Servicio de Corte Clásico:* `https://wa.me/57XXXXXXXXXX?text=Hola%20Andrés,%20vengo%20de%20la%20web%20y%20quiero%20agendar%20un%20Corte%20Clásico.`
  - *Servicio Barba & Ritual:* `https://wa.me/57XXXXXXXXXX?text=Hola%20Andrés,%20vengo%20de%20la%20web%20y%20quiero%20agendar%20Barba%20y%20Ritual.`
  - *Consulta de Horarios:* `https://wa.me/57XXXXXXXXXX?text=Hola%20Andrés,%20quisiera%20consultar%20disponibilidad%20para%20hoy.`

*(Esto permite que en la Fase 3, el nodo de OpenAI en N8N identifique la intención al instante sin tener que preguntarle al cliente qué quiere).*

---

## 🎨 4. Identidad Visual y Especificaciones Técnicas

- **Enfoque de Desarrollo:** HTML5 semántico + Vanilla CSS moderno + JavaScript ligero (cero dependencias pesadas, carga instantánea < 1.2 segundos).
- **Paleta de Colores sugerida (Premium & Elegante):**
  - Fondo Primario: `#0f1115` (Negro grafito profundo)
  - Fondo Secundario / Cards: `#181b22` (Gris carbón oscuro con bordes sutiles `#2a2f3a`)
  - Acentos / Highlights: `#d4af37` o `#c59b27` (Dorado mate / Oro viejo elegante)
  - Color de WhatsApp: `#25D366` (Verde oficial vibrante para el botón flotante y CTA clave)
  - Textos: `#f3f4f6` (Blanco suave para lectura) y `#9ca3af` (Gris tenue para subtítulos)
- **Tipografía:**
  - Títulos: *Outfit* o *Syne* (moderna, contundente)
  - Cuerpo: *Plus Jakarta Sans* o *Inter* (altamente legible en pantallas móviles)

---

## 📋 5. CHECKLIST DE EJECUCIÓN PASO A PASO

### 🟦 ETAPA 1: Preparación y Copywriting
- [x] **1.1** Recopilar datos reales de Andrés Peluquería (Logo oficial, fotos reales de Andrés y clientas, dirección Cra 83 # 09, especialidades).
- [x] **1.2** Redactar los textos persuasivos (copy) enfocados en balayage, diseño de color y tendencias sin filas.
- [x] **1.3** Organizar banco de imágenes reales en `landing/assets/images/`.

### 🟨 ETAPA 2: Estructura y Código (Frontend)
- [x] **2.1** Crear estructura de carpetas (`landing/index.html`, `styles.css`, `script.js`, `assets/images/`).
- [x] **2.2** Maquetar el HTML5 semántico completo (Header con estado en vivo, Hero, Catálogo de servicios, Sobre Andrés, Galería, FAQ, Footer, FAB).
- [x] **2.3** Diseñar el sistema de diseño en `styles.css` (variables CSS, paleta oscura premium, acentos dorados, tipografías Outfit y Plus Jakarta Sans).
- [x] **2.4** Diseñar componentes y micro-animaciones (ribbons de popularidad, hover effects, pulso verde de estado, glow effects).
- [x] **2.5** Implementar interactividad en `script.js` (acordeón FAQ, detector dinámico de abierto/cerrado, inyector de enlaces WhatsApp parametrizados y contenedor listo para videos).

### 🟩 ETAPA 3: Optimización, Testing & Mobile UX
- [ ] **3.1** Validar navegación en navegador del usuario (http://localhost:3000/ o abriendo landing/index.html).
- [ ] **3.2** Probar todos los enlaces directos a WhatsApp verificando que el texto predeterminado cargue correctamente.
- [ ] **3.3** Integrar los videos de Andrés cuando el usuario los suministre (mediante la función `integrateUserVideos`).
- [ ] **3.4** Configurar el número real de WhatsApp de Andrés en `landing/script.js`.

### 🟧 ETAPA 4: Despliegue y Conexión
- [ ] **4.1** Desplegar la Landing Page en hosting gratuito de alto rendimiento (Vercel / Cloudflare Pages).
- [ ] **4.2** Conectar dominio personalizado o subdominio.
- [ ] **4.3** Probar el embudo completo: Landing Page ➡️ Clic en CTA ➡️ Recepción del mensaje en WhatsApp listo para N8N.
