# 🤝 Guía de Contribución al Proyecto

¡Bienvenido al equipo de desarrollo de **Andrés Peluquería**! Para mantener la arquitectura limpia, prevenir errores en producción y evitar el "código espagueti", todos los miembros del equipo deben seguir estas directrices.

---

## 🌿 1. Estrategia de Ramas (Git Flow Simplificado)

Trabajamos con tres niveles de ramas:

1. **`main` (Producción):**
   - Código 100% probado, estable y listo para desplegar.
   - Protegido contra commits directos; solo se integra mediante Pull Requests aprobados.
2. **`dev` (Integración):**
   - Rama principal de desarrollo donde se unen las características completadas.
3. **`feature/<nombre-tarea>` (Funcionalidades):**
   - Ramas temporales creadas desde `dev`.
   - Ejemplos: `feature/landing-videos`, `feature/n8n-debounce-node`, `feature/postgres-schema`.
4. **`fix/<nombre-bug>` (Corrección de errores):**
   - Ejemplos: `fix/whatsapp-link-encoding`, `fix/calendar-timezones`.

---

## 📝 2. Convención de Mensajes de Commit (Conventional Commits)

Utilizamos el estándar semántico para que el historial sea legible y profesional:

```text
<tipo>: <descripción concisa en imperativo y minúsculas>

[cuerpo opcional explicando el porqué del cambio]
```

### Tipos Permitidos:
- **`feat:`** Nueva funcionalidad (ej. `feat: agregar contenedor para videos en landing page`).
- **`fix:`** Corrección de un fallo (ej. `fix: corregir cálculo de horario de cierre los domingos`).
- **`docs:`** Cambios exclusivamente en documentación (ej. `docs: actualizar roadmap de fase 2`).
- **`style:`** Formateo, estilos CSS, espacios o comas sin cambiar lógica (ej. `style: ajustar gradiente dorado en cta principal`).
- **`refactor:`** Reestructuración de código sin agregar funciones ni romper nada.
- **`chore:`** Tareas de mantenimiento o configuración (ej. `chore: actualizar .gitignore y variables de entorno`).

---

## 🛡️ 3. Reglas de Calidad antes de Enviar un Pull Request (PR)

Antes de solicitar la integración de tu rama a `dev` o `main`:

1. **Verificar que no haya secretos expuestos:** Ningún `.env`, API key de OpenAI/Gemini ni token de Meta debe estar en el commit.
2. **Probar localmente:** Si tocaste la landing, corre `node landing/serve.js` y valida que cargue sin errores en la consola del navegador.
3. **Respetar la nomenclatura:** Nombres en `snake_case` para bases de datos y prefijos `DS-XX` / `T-XX` para flujos de n8n.
4. **Documentar cambios relevantes:** Si agregas una variable de entorno, agrégala con valor ficticio en `infra/.env.example`.
