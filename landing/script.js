/**
 * ANDRÉS DÍAZ - TENDENCIA EN PELUQUERÍA
 * Lógica del Embudo de Captura a WhatsApp & Estados en Vivo
 */

document.addEventListener('DOMContentLoaded', () => {

  // ========================================================
  // 1. CONFIGURACIÓN CENTRALIZADA DEL NEGOCIO
  // (Modifica el número de WhatsApp aquí y se actualizará en toda la web)
  // ========================================================
  const BUSINESS_CONFIG = {
    // Ingresa el número con indicativo internacional (Ej: 57 para Colombia + 3XXXXXXXXX)
    whatsappNumber: '573000000000', 
    businessName: 'Andrés Díaz Peluquería',
    schedule: {
      weekdays: { open: 9, close: 20 }, // Lunes a Sábado: 9:00 AM a 8:00 PM
      sunday: { open: 10, close: 16 }    // Domingos: 10:00 AM a 4:00 PM
    }
  };

  // ========================================================
  // 2. GENERADOR DINÁMICO DE ENLACES A WHATSAPP (wa.me)
  // (Inyecta la intención exacta para que el agente en N8N la procese)
  // ========================================================
  function initWhatsAppTriggers() {
    const waTriggers = document.querySelectorAll('.whatsapp-trigger');

    waTriggers.forEach(button => {
      const service = button.getAttribute('data-service') || 'General';
      let message = '';

      switch (service) {
        case 'Balayage Signature & Diseño de Color':
          message = `Hola Andrés, estuve viendo la web y quiero agendar una cita o valoración para Balayage Signature & Diseño de Color. ¿Qué fechas tienes disponibles?`;
          break;
        case 'Corte de Tendencia & Styling':
          message = `Hola Andrés, vengo de la web y quiero agendar mi cita para Corte de Tendencia & Styling. ¿Qué horarios tienes libres?`;
          break;
        case 'Terapia Nutritiva & Reparación':
          message = `Hola Andrés, vi la Terapia de Hidratación & Reparación en la web y quiero agendar una sesión para recuperar mi cabello.`;
          break;
        case 'Mantenimiento de Tono & Brillo Gloss':
          message = `Hola Andrés, quiero agendar un Mantenimiento de Tono y Brillo Gloss para renovar mi color.`;
          break;
        case 'Diagnóstico con Andrés Díaz':
          message = `Hola Andrés, me gustaría solicitar un diagnóstico personalizado para mi cabello antes de realizarme un cambio de look.`;
          break;
        case 'Botón Flotante Rápido':
          message = `Hola Andrés, estoy en tu página web y tengo una consulta para agendar una cita.`;
          break;
        case 'Consulta de Ubicación y Cita':
          message = `Hola Andrés, vi la ubicación de tu salón y quiero agendar una cita para esta semana.`;
          break;
        default:
          message = `Hola Andrés, quiero agendar una cita en el salón. ¿Me puedes compartir los horarios disponibles?`;
          break;
      }

      const encodedMessage = encodeURIComponent(message);
      const waUrl = `https://wa.me/${BUSINESS_CONFIG.whatsappNumber}?text=${encodedMessage}`;
      
      button.setAttribute('href', waUrl);
      button.setAttribute('target', '_blank');
      button.setAttribute('rel', 'noopener noreferrer');
    });
  }

  // ========================================================
  // 3. DETECTOR DE ESTADO EN VIVO (ABIERTO / CERRADO)
  // ========================================================
  function updateBusinessStatus() {
    const statusDot = document.getElementById('statusDot');
    const statusText = document.getElementById('statusText');
    const statusPillBig = document.getElementById('statusPillBig');

    const now = new Date();
    const day = now.getDay(); // 0 = Domingo, 1-6 = Lunes a Sábado
    const currentHour = now.getHours();

    let isOpen = false;
    let closingTime = '';

    if (day === 0) { // Domingo
      if (currentHour >= BUSINESS_CONFIG.schedule.sunday.open && currentHour < BUSINESS_CONFIG.schedule.sunday.close) {
        isOpen = true;
        closingTime = '4:00 PM';
      }
    } else { // Lunes a Sábado
      if (currentHour >= BUSINESS_CONFIG.schedule.weekdays.open && currentHour < BUSINESS_CONFIG.schedule.weekdays.close) {
        isOpen = true;
        closingTime = '8:00 PM';
      }
    }

    if (isOpen) {
      if (statusDot) statusDot.style.backgroundColor = '#22c55e';
      if (statusText) statusText.textContent = `Abierto ahora • Cierra a las ${closingTime}`;
      if (statusPillBig) {
        statusPillBig.textContent = `🟢 Abierto hoy hasta las ${closingTime}`;
        statusPillBig.style.borderColor = 'rgba(34, 197, 94, 0.4)';
        statusPillBig.style.color = '#4ade80';
      }
    } else {
      if (statusDot) {
        statusDot.style.backgroundColor = '#f59e0b';
        statusDot.style.boxShadow = 'none';
        statusDot.style.animation = 'none';
      }
      if (statusText) statusText.textContent = `Cerrado por ahora • Asistente WhatsApp activo 24/7`;
      if (statusPillBig) {
        statusPillBig.textContent = `🌙 Cerrado • Agendando citas 24/7 en WhatsApp`;
        statusPillBig.style.borderColor = 'rgba(245, 158, 11, 0.4)';
        statusPillBig.style.color = '#fbbf24';
      }
    }
  }

  // ========================================================
  // 4. ACORDEÓN DE PREGUNTAS FRECUENTES (FAQ)
  // ========================================================
  function initFaqAccordion() {
    const accordionHeaders = document.querySelectorAll('.accordion-header');

    accordionHeaders.forEach(header => {
      header.addEventListener('click', () => {
        const item = header.parentElement;
        const content = header.nextElementSibling;
        const isActive = item.classList.contains('active');

        // Cerrar todos los demás
        document.querySelectorAll('.accordion-item').forEach(otherItem => {
          if (otherItem !== item) {
            otherItem.classList.remove('active');
            otherItem.querySelector('.accordion-header').setAttribute('aria-expanded', 'false');
            otherItem.querySelector('.accordion-content').style.maxHeight = null;
          }
        });

        // Alternar el actual
        if (isActive) {
          item.classList.remove('active');
          header.setAttribute('aria-expanded', 'false');
          content.style.maxHeight = null;
        } else {
          item.classList.add('active');
          header.setAttribute('aria-expanded', 'true');
          content.style.maxHeight = content.scrollHeight + 'px';
        }
      });
    });
  }

  // ========================================================
  // 5. HOOK PARA INTEGRACIÓN DE VIDEOS POSTERIORMENTE
  // (Función lista para cuando el usuario pase los videos)
  // ========================================================
  window.integrateUserVideos = function(videoUrls = []) {
    const container = document.getElementById('videoPlaceholder');
    if (!container || videoUrls.length === 0) return;

    let html = '<div class="videos-grid" style="display:grid; grid-template-columns:repeat(auto-fit, minmax(280px, 1fr)); gap:1.25rem;">';
    videoUrls.forEach((video, index) => {
      html += `
        <div class="video-card" style="border-radius:16px; overflow:hidden; border:1px solid var(--border-gold); background:var(--bg-card);">
          <video controls playsinline style="width:100%; display:block; border-radius:16px;" src="${video.src}" poster="${video.poster || ''}">
            Tu navegador no soporta videos HTML5.
          </video>
          <div style="padding:0.75rem 1rem; font-size:0.85rem; color:var(--gold-light); font-weight:600;">
            ${video.title || `Transformación #${index + 1}`}
          </div>
        </div>
      `;
    });
    html += '</div>';

    container.innerHTML = html;
  };

  // Inicializar componentes
  initWhatsAppTriggers();
  updateBusinessStatus();
  initFaqAccordion();
});
