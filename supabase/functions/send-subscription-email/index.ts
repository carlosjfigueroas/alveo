import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const payload = await req.json()
    const { type, target_email, referrer_company_name, register_link, locale, company_id, password } = payload
    
    const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')
    
    // --- HANDLE WELCOME AUTO REGISTER ---
    if (type === 'welcome_auto_register') {
      const { data: company, error: coError } = await supabaseAdmin
        .from('companies')
        .select('*')
        .eq('id', company_id)
        .single()
      
      if (coError || !company) throw new Error('Company not found')

      const isEn = company.language === 'en'
      const portalUrl = `https://${company.domain}/?clear_cache=1`
      
      const t = {
        subject: isEn ? "Welcome to Alveo - Your Portal is Ready" : "Bienvenido a Alveo - Tu Portal está Listo",
        title: isEn ? "Welcome to Alveo" : "Bienvenido a Alveo",
        intro: isEn 
          ? `Hello ${company.contact_name}, your real estate portal for <strong>${company.name}</strong> has been successfully created.` 
          : `Hola ${company.contact_name}, tu portal inmobiliario para <strong>${company.name}</strong> ha sido creado con éxito.`,
        credsTitle: isEn ? "Your Access Credentials:" : "Tus Credenciales de Acceso:",
        userLabel: isEn ? "User/Email:" : "Usuario/Email:",
        passLabel: isEn ? "Password:" : "Contraseña:",
        portalLabel: isEn ? "Your Portal URL:" : "URL de tu Portal:",
        cta: isEn ? "Go to my Portal" : "Ir a mi Portal",
        footer: isEn ? "We recommend changing your password after your first login." : "Te recomendamos cambiar tu contraseña después de tu primer inicio de sesión.",
      }

      const welcomeHtml = `
      <div style="font-family: 'Segoe UI', Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden;">
        <div style="background-color: #006837; padding: 40px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 28px;">ALVEO</h1>
          <p style="margin: 10px 0 0 0; font-size: 18px; opacity: 0.9;">${t.title}</p>
        </div>
        <div style="padding: 40px; background-color: #ffffff;">
          <p style="font-size: 16px; line-height: 1.6; color: #444;">${t.intro}</p>
          
          <div style="margin: 30px 0; padding: 25px; background-color: #f9f9f9; border-radius: 12px; border: 1px solid #eee;">
            <h4 style="margin: 0 0 15px 0; color: #006837; text-transform: uppercase; font-size: 13px; letter-spacing: 1px;">${t.credsTitle}</h4>
            <p style="margin: 5px 0; font-size: 15px;"><strong>${t.userLabel}</strong> ${company.contact_email}</p>
            <p style="margin: 5px 0; font-size: 15px;"><strong>${t.passLabel}</strong> ${password}</p>
            <p style="margin: 15px 0 5px 0; font-size: 14px; color: #666;"><strong>${t.portalLabel}</strong><br/><a href="${portalUrl}">${portalUrl}</a></p>
          </div>
          
          <div style="text-align: center; margin-top: 40px;">
            <a href="${portalUrl}" style="background-color: #006837; color: white; padding: 18px 35px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block;">
              ${t.cta}
            </a>
          </div>
          
          <p style="margin-top: 40px; font-size: 13px; text-align: center; color: #888;">
            ${t.footer}
          </p>
        </div>
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #aaa; border-top: 1px solid #eee;">
          © ${new Date().getFullYear()} Alveo Platform. All rights reserved.
        </div>
      </div>
      `

      if (!BREVO_API_KEY) throw new Error("No BREVO_API_KEY found")

      const res = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-key': BREVO_API_KEY,
        },
        body: JSON.stringify({
          sender: { name: "Alveo Platform", email: "alveo.soporte@gmail.com" },
          to: [{ email: company.contact_email }],
          subject: t.subject,
          htmlContent: welcomeHtml
        }),
      })

      if (!res.ok) {
        const errorData = await res.json()
        console.error("Brevo Error:", errorData)
        throw new Error(`Brevo Error: ${JSON.stringify(errorData)}`)
      }

      const data = await res.json()
      console.log("Brevo Success Response:", data)
      console.log("Welcome Payload used:", { company_id, target_email: company.contact_email })
      
      return new Response(JSON.stringify({ message: "Welcome email sent", data }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // --- HANDLE INVITE FRIEND ---
    if (type === 'invite_friend') {
      const isEn = locale === 'en';
      if (!BREVO_API_KEY) throw new Error("No BREVO_API_KEY found")

      const t = {
        subject: isEn ? `Invitation to Alveo - From ${referrer_company_name}` : `Invitación a Alveo - De parte de ${referrer_company_name}`,
        title: isEn ? "Grow your Real Estate Agency" : "Crece con tu Inmobiliaria",
        intro: isEn 
          ? `<strong>${referrer_company_name}</strong> invites you to join Alveo, the most advanced platform for managing real estate inventory and leads.` 
          : `<strong>${referrer_company_name}</strong> te invita a unirte a Alveo, la plataforma más avanzada para gestionar inventario inmobiliario y leads.`,
        benefitTitle: isEn ? "Exclusive Referral Benefits:" : "Beneficios exclusivos por referido:",
        benefit1: isEn ? "+2 Property capacity limit" : "+2 Inmuebles de límite en tu plan",
        benefit2: isEn ? "+2 Photos per property" : "+2 Fotos adicionales por inmueble",
        benefit3: isEn ? "$1 Monthly discount (accumulative)" : "$1 de descuento mensual (acumulable)",
        cta: isEn ? "Create my account now" : "Crear mi cuenta ahora",
        footer: isEn ? "Start your 7-day free trial today." : "Comienza hoy mismo tu prueba gratuita de 7 días.",
      }

      const inviteHtml = `
      <div style="font-family: 'Segoe UI', Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden;">
        <div style="background-color: #006837; padding: 40px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 28px;">ALVEO</h1>
          <p style="margin: 10px 0 0 0; font-size: 18px; opacity: 0.9;">${t.title}</p>
        </div>
        <div style="padding: 40px; background-color: #ffffff;">
          <p style="font-size: 16px; line-height: 1.6; color: #444;">${t.intro}</p>
          
          <div style="margin: 30px 0; padding: 25px; background-color: #f0f7f3; border-radius: 12px; border: 1px dashed #006837;">
            <h4 style="margin: 0 0 15px 0; color: #006837; text-transform: uppercase; font-size: 13px; letter-spacing: 1px;">${t.benefitTitle}</h4>
            <ul style="margin: 0; padding: 0; list-style: none;">
              <li style="margin-bottom: 10px; font-size: 15px;">✅ ${t.benefit1}</li>
              <li style="margin-bottom: 10px; font-size: 15px;">✅ ${t.benefit2}</li>
              <li style="margin-bottom: 10px; font-size: 15px;">✅ ${t.benefit3}</li>
            </ul>
          </div>
          
          <div style="text-align: center; margin-top: 40px;">
            <a href="${register_link}" style="background-color: #006837; color: white; padding: 18px 35px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block;">
              ${t.cta}
            </a>
          </div>
          
          <p style="margin-top: 40px; font-size: 14px; text-align: center; color: #888;">
            ${t.footer}
          </p>
        </div>
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #aaa; border-top: 1px solid #eee;">
          © ${new Date().getFullYear()} Alveo Platform. All rights reserved.
        </div>
      </div>
      `

      const res = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-key': BREVO_API_KEY,
        },
        body: JSON.stringify({
          sender: { name: "Alveo Platform", email: "alveo.soporte@gmail.com" },
          to: [{ email: target_email }],
          subject: t.subject,
          htmlContent: inviteHtml
        }),
      })

      if (!res.ok) {
        const errorData = await res.json()
        console.error("Brevo Error:", errorData)
        throw new Error(`Brevo Error: ${JSON.stringify(errorData)}`)
      }

      const data = await res.json()
      console.log("Brevo Success Response:", data)
      console.log("Payload used:", { target_email, referrer_company_name, locale })
      
      return new Response(JSON.stringify({ message: "Invitation email sent", data }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // --- HANDLE BILLING / SUBSCRIPTION EMAILS ---
    if (['payment_reported', 'payment_confirmed', 'payment_reminder', 'suspended', 'reactivated'].includes(type)) {
      const { data: company, error: coError } = await supabaseAdmin
        .from('companies')
        .select('*')
        .eq('id', company_id)
        .single()
      
      if (coError || !company) throw new Error('Company not found')

      const isEn = company.language === 'en'
      const portalUrl = `https://${company.domain}`
      let subject = ''
      let title = ''
      let htmlBody = ''

      if (type === 'payment_reported') {
        subject = isEn ? "Payment Received - Pending Verification" : "Pago Recibido - Pendiente de Verificación"
        title = isEn ? "Payment Reported" : "Pago Reportado"
        htmlBody = isEn 
          ? `<p>Hello ${company.contact_name},</p><p>We have successfully received your payment report for <strong>${company.name}</strong>. Our team will verify it shortly and your service will be reactivated automatically.</p>`
          : `<p>Hola ${company.contact_name},</p><p>Hemos recibido exitosamente el reporte de pago para <strong>${company.name}</strong>. Nuestro equipo lo verificará a la brevedad y tu servicio será reactivado automáticamente.</p>`
      } else if (type === 'payment_confirmed') {
        subject = isEn ? "Payment Confirmed - Service Active" : "Pago Confirmado - Servicio Activo"
        title = isEn ? "Payment Confirmed" : "Pago Confirmado"
        htmlBody = isEn 
          ? `<p>Hello ${company.contact_name},</p><p>Your payment for <strong>${company.name}</strong> has been confirmed. Your subscription is now active.</p><p>You can access your portal here: <a href="${portalUrl}">${portalUrl}</a></p>`
          : `<p>Hola ${company.contact_name},</p><p>Tu pago para <strong>${company.name}</strong> ha sido confirmado. Tu suscripción ya está activa.</p><p>Puedes acceder a tu portal aquí: <a href="${portalUrl}">${portalUrl}</a></p>`
      } else if (type === 'payment_reminder') {
        subject = isEn ? "Action Required: Upcoming Subscription Renewal" : "Acción Requerida: Próxima Renovación de Suscripción"
        title = isEn ? "Payment Reminder" : "Recordatorio de Pago"
        htmlBody = isEn 
          ? `<p>Hello ${company.contact_name},</p><p>This is a friendly reminder that the subscription for <strong>${company.name}</strong> will expire soon. Please ensure your payment is up to date to avoid service interruption.</p>`
          : `<p>Hola ${company.contact_name},</p><p>Este es un recordatorio amistoso de que la suscripción para <strong>${company.name}</strong> vencerá pronto. Por favor asegúrate de que tu pago esté al día para evitar la interrupción del servicio.</p>`
      } else if (type === 'suspended') {
        subject = isEn ? "Important: Service Suspended" : "Importante: Servicio Suspendido"
        title = isEn ? "Service Suspended" : "Servicio Suspendido"
        htmlBody = isEn 
          ? `<p>Hello ${company.contact_name},</p><p>Your service for <strong>${company.name}</strong> has been temporarily suspended due to a pending payment.</p><p>Please visit <a href="${portalUrl}">${portalUrl}</a> to report your payment and reactivate your account.</p>`
          : `<p>Hola ${company.contact_name},</p><p>Tu servicio para <strong>${company.name}</strong> ha sido suspendido temporalmente por falta de pago.</p><p>Por favor visita <a href="${portalUrl}">${portalUrl}</a> para reportar tu pago y reactivar tu cuenta.</p>`
      } else if (type === 'reactivated') {
        subject = isEn ? "Service Reactivated" : "Servicio Reactivado"
        title = isEn ? "Service Active" : "Servicio Activo"
        htmlBody = isEn 
          ? `<p>Hello ${company.contact_name},</p><p>Good news! Your service for <strong>${company.name}</strong> has been fully reactivated.</p><p>You can access your portal here: <a href="${portalUrl}">${portalUrl}</a></p>`
          : `<p>Hola ${company.contact_name},</p><p>¡Buenas noticias! Tu servicio para <strong>${company.name}</strong> ha sido reactivado exitosamente.</p><p>Puedes acceder a tu portal aquí: <a href="${portalUrl}">${portalUrl}</a></p>`
      }

      const emailHtml = `
      <div style="font-family: 'Segoe UI', Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden;">
        <div style="background-color: #006837; padding: 40px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 28px;">ALVEO</h1>
          <p style="margin: 10px 0 0 0; font-size: 18px; opacity: 0.9;">${title}</p>
        </div>
        <div style="padding: 40px; background-color: #ffffff;">
          <div style="font-size: 16px; line-height: 1.6; color: #444;">
            ${htmlBody}
          </div>
          <p style="margin-top: 40px; font-size: 13px; text-align: center; color: #888;">
            ${isEn ? "If you have any questions, please contact our support team." : "Si tienes alguna pregunta, por favor contacta a nuestro equipo de soporte."}
          </p>
        </div>
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #aaa; border-top: 1px solid #eee;">
          © ${new Date().getFullYear()} Alveo Platform. All rights reserved.
        </div>
      </div>
      `

      if (!BREVO_API_KEY) throw new Error("No BREVO_API_KEY found")

      const res = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-key': BREVO_API_KEY,
        },
        body: JSON.stringify({
          sender: { name: "Alveo Platform", email: "alveo.soporte@gmail.com" },
          to: [{ email: company.contact_email }],
          subject: subject,
          htmlContent: emailHtml
        }),
      })

      if (!res.ok) {
        const errorData = await res.json()
        console.error("Brevo Error:", errorData)
        throw new Error(`Brevo Error: ${JSON.stringify(errorData)}`)
      }

      const data = await res.json()
      console.log(`Brevo Success Response (${type}):`, data)
      console.log("Billing Payload used:", { type, company_id, target_email: company.contact_email })
      
      return new Response(JSON.stringify({ message: `${type} email sent`, data }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    return new Response(JSON.stringify({ error: 'Unsupported email type' }), { status: 400, headers: corsHeaders })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders })
  }
})
