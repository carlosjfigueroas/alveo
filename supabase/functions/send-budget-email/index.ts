import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    const { 
      name, email, phone, notes, propertyIds, propertyDetails, locale, 
      companyEmail, companyName, primaryColor, secondaryColor, agentEmail,
      isUpdate, updateType, appointmentDate, appointmentTime 
    } = payload
    
    const isEn = locale === 'en';
    const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')
    const prop = propertyDetails && propertyDetails.length > 0 ? propertyDetails[0] : null
    
    // Theme colors
    const pColor = primaryColor || '#006837';
    const sColor = secondaryColor || '#00BFA5';

    // Business Logic for Branding
    const displayCompany = companyName || 'Alveo Real Estate';
    const autoFallbackEmail = companyEmail && typeof companyEmail === 'string' && companyEmail.includes('@') ? companyEmail : 'alveo.soporte@gmail.com';

    // Translation dictionary
    const t = {
      title: isEn ? "Official Quotation" : "Presupuesto Oficial",
      greeting: isEn ? "Hello" : "Hola",
      intro: isEn ? "Thank you for your interest. Below is the preliminary quotation for the requested property:" : "Gracias por tu interés en nuestros espacios. A continuación, te presentamos el presupuesto preliminar para el inmueble que solicitaste:",
      propLabel: isEn ? "Property:" : "Inmueble:",
      opLabel: isEn ? "Operation Type:" : "Tipo Operación:",
      typeLabel: isEn ? "Property Type:" : "Tipo Inmueble:",
      priceLabel: isEn ? "Price:" : "Precio:",
      notesTitle: isEn ? "Your notes:" : "Tus notas:",
      noNotes: isEn ? "No additional notes" : "Sin notas adicionales",
      footerMsg: isEn ? "Our team will contact you very soon at phone number" : "Nuestro equipo te contactará muy pronto al teléfono",
      footerEnd: isEn ? "to provide personalized assistance and refine the details of this quotation." : "para brindarte asesoría personalizada y afinar los detalles de este presupuesto.",
      autoMsg: isEn ? "This email was generated automatically. For assistance, contact:" : "Este correo fue generado automáticamente. Para asistencia, contáctenos a:",
      consult: isEn ? "Consult" : "Consultar",
      propUnknown: isEn ? "Property" : "Inmueble",
      na: "N/A",
      subjectText: isEn ? "Quotation" : "Presupuesto",
    }

    // Fallback if prop not found
    const propTitle = prop ? prop.title : t.propUnknown
    const propPrice = prop ? `$${prop.price}` : t.consult
    const propOperation = prop ? prop.operation : t.na;

    let propType = t.propUnknown;
    if (prop) {
      if (isEn) {
           if (prop.type === 'local') propType = 'Commercial Space';
           else if (prop.type === 'oficina') propType = 'Office';
           else if (prop.type === 'galpon') propType = 'Warehouse';
           else propType = prop.type;
      } else {
          propType = prop.type;
      }
    }

    let propOperationT = propOperation;
    if (isEn && prop) {
        if (prop.operation === 'venta') propOperationT = 'Sale';
        else if (prop.operation === 'alquiler') propOperationT = 'Rent';
    }

    let emailHtml = "";
    let subjectLine = "";
    let agencySubjectLine = "";

    if (isUpdate) {
      const isConfirmed = updateType === 'confirm';
      const isRescheduled = updateType === 'reschedule';
      const isDone = updateType === 'done';
      const isCancelled = updateType === 'cancel' || updateType === 'delete';

      let statusText = updateType;
      let statusColor = '#E65100'; // orange
      if (isConfirmed) { statusText = isEn ? 'CONFIRMED' : 'CONFIRMADA'; statusColor = '#2E7D32'; }
      else if (isRescheduled) { statusText = isEn ? 'RESCHEDULED' : 'REPROGRAMADA'; statusColor = '#1565C0'; }
      else if (isDone) { statusText = isEn ? 'REALIZED' : 'REALIZADA'; statusColor = '#37474F'; }
      else if (isCancelled) { statusText = isEn ? 'CANCELLED' : 'CANCELADA'; statusColor = '#C62828'; }

      const updateTitle = isEn ? "Appointment Update Notification" : "Actualización de Cita Inmobiliaria";
      agencySubjectLine = `[ACTUALIZACIÓN CITA: ${statusText}] ${name} - ${displayCompany}`;

      emailHtml = `
      <div style="font-family: 'Segoe UI', Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.08);">
        <div style="background-color: ${pColor}; padding: 30px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 20px; font-weight: 300;">${updateTitle}</h1>
          <p style="margin: 10px 0 0 0; font-size: 18px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">${displayCompany}</p>
        </div>
        <div style="padding: 35px;">
          <p style="font-size: 16px;">${isEn ? 'Hello Agent' : 'Hola Agente'},</p>
          <p style="font-size: 15px; line-height: 1.6; color: #555;">
            ${isEn ? `The appointment with the client **${name}** has registered an update in the system.` : `La cita con el cliente **${name}** ha registrado una actualización en el sistema.`}
          </p>
          
          <table style="width: 100%; border-collapse: collapse; margin-top: 30px; background-color: #fcfcfc; border-radius: 8px; overflow: hidden;">
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Client:' : 'Cliente:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${name}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Phone:' : 'Teléfono:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${phone}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Property:' : 'Inmueble:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${propTitle}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Status/Action:' : 'Estado/Acción:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: ${statusColor}; font-size: 16px; text-transform: uppercase;">${statusText}</td>
            </tr>
            ${appointmentDate ? `
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Date:' : 'Fecha Cita:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${appointmentDate}</td>
            </tr>` : ''}
            ${appointmentTime ? `
            <tr>
              <td style="padding: 15px; color: #666; font-size: 14px;">${isEn ? 'Time:' : 'Hora Cita:'}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${appointmentTime.substring(0, 5)}</td>
            </tr>` : ''}
          </table>
          
          <div style="margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-left: 4px solid ${statusColor}; border-radius: 4px;">
            <h4 style="margin: 0 0 8px 0; font-size: 13px; color: ${pColor}; text-transform: uppercase;">${isEn ? 'Details:' : 'Detalles de Bitácora:'}</h4>
            <p style="margin: 0; font-size: 15px; color: #444; font-style: italic;">"${notes || (isEn ? 'No additional notes provided.' : 'Sin notas adicionales.')}"</p>
          </div>
          
          <div style="margin-top: 35px; border-top: 1px solid #eee; padding-top: 25px; text-align: center;">
              <p style="margin: 0; font-size: 13px; color: #444; font-weight: bold;">${displayCompany}</p>
              <p style="margin: 5px 0 0 0; font-size: 12px; color: #888;">${isEn ? 'Transactional update sent automatically by Alveo.' : 'Correo transaccional enviado automáticamente por Alveo.'}</p>
          </div>
        </div>
      </div>
      `;
    } else {
      subjectLine = `${t.subjectText} - ${displayCompany} [${propTitle}]`;
      agencySubjectLine = `[NUEVO LEAD] ${t.subjectText} - ${displayCompany} [${propTitle}]`;
      emailHtml = `
      <div style="font-family: 'Segoe UI', Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.08);">
        <div style="background-color: ${pColor}; padding: 30px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 24px; font-weight: 300;">${t.title}</h1>
          <p style="margin: 10px 0 0 0; font-size: 18px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">${displayCompany}</p>
        </div>
        <div style="padding: 35px;">
          <p style="font-size: 16px;">${t.greeting} <strong>${name}</strong>,</p>
          <p style="font-size: 15px; line-height: 1.6; color: #555;">${t.intro}</p>
          
          <table style="width: 100%; border-collapse: collapse; margin-top: 30px; background-color: #fcfcfc; border-radius: 8px; overflow: hidden;">
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${t.propLabel}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; color: #111;">${propTitle}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${t.opLabel}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; text-transform: capitalize; color: #111;">${propOperationT}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 15px; color: #666; font-size: 14px;">${t.typeLabel}</td>
              <td style="padding: 15px; text-align: right; font-weight: bold; text-transform: capitalize; color: #111;">${propType}</td>
            </tr>
            <tr>
              <td style="padding: 25px 15px; font-size: 18px; font-weight: bold; color: ${pColor};">${t.priceLabel}</td>
              <td style="padding: 25px 15px; font-size: 24px; font-weight: bold; color: ${sColor}; text-align: right;">${propPrice}</td>
            </tr>
          </table>
          
          <div style="margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-left: 4px solid ${sColor}; border-radius: 4px;">
            <h4 style="margin: 0 0 8px 0; font-size: 13px; color: ${pColor}; text-transform: uppercase;">${t.notesTitle}</h4>
            <p style="margin: 0; font-size: 15px; color: #444; font-style: italic;">"${notes || t.noNotes}"</p>
          </div>
          
          <p style="margin-top: 40px; font-size: 14px; text-align: center; color: #666; line-height: 1.6;">
            ${t.footerMsg} <strong style="color: ${pColor};">${phone}</strong> ${t.footerEnd}
          </p>
          
          <div style="margin-top: 35px; border-top: 1px solid #eee; padding-top: 25px; text-align: center;">
              <p style="margin: 0; font-size: 13px; color: #444; font-weight: bold;">${displayCompany}</p>
              <p style="margin: 5px 0 0 0; font-size: 12px; color: #888;">${t.autoMsg} ${autoFallbackEmail}</p>
          </div>
        </div>
      </div>
      `;
    }

    if (!BREVO_API_KEY) {
      console.warn("No BREVO_API_KEY found.");
      return new Response(
        JSON.stringify({ message: "Simulated email sent successfully (check logs)" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const adminEmail = autoFallbackEmail;
    const clientEmail = email && typeof email === 'string' && email.includes('@') ? email : null;
    const validAgentEmail = agentEmail && typeof agentEmail === 'string' && agentEmail.includes('@') ? agentEmail : null;

    const sender = {
        name: displayCompany,
        email: "alveo.soporte@gmail.com"
    };

    // 1. Enviar correo al Cliente (Prospecto) - Solo si NO es una actualización
    if (clientEmail && !isUpdate) {
      const clientPayload = {
          sender: sender,
          to: [{ email: clientEmail }],
          subject: subjectLine,
          htmlContent: emailHtml
      };
      await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-key': BREVO_API_KEY,
        },
        body: JSON.stringify(clientPayload),
      }).catch(e => console.error("Error sending to client:", e));
    }

    // 2. Enviar correo al Agente o Administrador
    const agencyEmailTo = validAgentEmail ? validAgentEmail : adminEmail;
    const agencyPayload = {
        sender: sender,
        to: [{ email: agencyEmailTo }],
        subject: agencySubjectLine,
        htmlContent: emailHtml
    };
    
    // Si el agente y el admin son distintos y queremos notificar a ambos, podríamos agregarlo en CC o hacer otro envío,
    // pero la regla dice "al agente o al administrador".
    const resBrevo = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'api-key': BREVO_API_KEY,
      },
      body: JSON.stringify(agencyPayload),
    });

    const brevoData = await resBrevo.json().catch(() => ({ error: "Failed to parse Brevo response" }));
    
    if (!resBrevo.ok) {
        return new Response(
            JSON.stringify({ error: brevoData?.message || 'Brevo error' }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
        )
    }
    
    return new Response(
      JSON.stringify({ message: "Email sent successfully", data: brevoData }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error("Function exception:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    )
  }
})