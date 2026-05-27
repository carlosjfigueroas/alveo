import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const tools = [
  {
    functionDeclarations: [
      {
        name: "buscar_propiedades",
        description: "Busca propiedades en el inventario de la empresa. Soporta filtros específicos de comodidades, áreas, niveles y búsqueda de texto libre.",
        parameters: {
          type: "OBJECT",
          properties: {
            operationType: {
              type: "STRING",
              description: "Tipo de operacion: 'Alquiler' o 'Venta'"
            },
            propertyType: {
              type: "STRING",
              description: "Tipo de propiedad: 'Casa', 'Apartamento', 'Local', 'Terreno', 'Galpon', 'Oficina', 'Penthouse', 'Atico', 'Duplex', 'Loft', 'Estudio', 'Posada', 'Hotel', 'Tienda'"
            },
            city: {
              type: "STRING",
              description: "Ciudad donde se busca la propiedad"
            },
            maxPrice: {
              type: "NUMBER",
              description: "Precio maximo del cliente en USD"
            },
            minBedrooms: {
              type: "NUMBER",
              description: "Numero minimo de habitaciones"
            },
            searchQuery: {
              type: "STRING",
              description: "Palabra clave o concepto libre buscado (ej: 'vista al mar', 'cerca de clinica', 'pozo de agua')"
            },
            minArea: {
              type: "NUMBER",
              description: "Area minima en metros cuadrados (m²)"
            },
            bathrooms: {
              type: "NUMBER",
              description: "Numero minimo de banos"
            },
            parkingSpaces: {
              type: "NUMBER",
              description: "Numero minimo de puestos de estacionamiento"
            },
            isFurnished: {
              type: "BOOLEAN",
              description: "Filtrar si el inmueble debe estar amoblado/equipado (true) o no (false)"
            },
            hasPool: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener piscina (true/false)"
            },
            hasAirCon: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener aire acondicionado (true/false)"
            },
            hasPowerGenerator: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener planta electrica (true/false)"
            },
            hasWaterTank: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener tanque de agua o pozo (true/false)"
            },
            hasSecurity: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener vigilancia/seguridad (true/false)"
            },
            hasElevator: {
              type: "BOOLEAN",
              description: "Filtrar si debe tener ascensor (true/false)"
            },
            deliveryStatus: {
              type: "STRING",
              description: "Estado de entrega: 'Obra gris', 'Semi acabado', 'Listo para ocupar'"
            },
            floorLevel: {
              type: "STRING",
              description: "Nivel de piso preferido (ej: 'Planta baja')"
            }
          }
        }
      },
      {
        name: "detalle_propiedad",
        description: "Obtiene todos los detalles de una propiedad especifica usando su ref_number (ej. 1024).",
        parameters: {
          type: "OBJECT",
          properties: {
            refNumber: {
              type: "NUMBER",
              description: "El numero de referencia unico de la propiedad"
            }
          },
          required: ["refNumber"]
        }
      },
      {
        name: "generar_link_propiedad",
        description: "Genera el link publico de una propiedad para que el usuario pueda verla en el navegador.",
        parameters: {
          type: "OBJECT",
          properties: {
            refNumber: {
              type: "NUMBER",
              description: "El numero de referencia unico de la propiedad"
            }
          },
          required: ["refNumber"]
        }
      },
      {
        name: "registrar_solicitud_visita",
        description: "Registra una solicitud de visita o interés de un cliente para una propiedad específica en la base de datos (CRM). Debe llamarse cuando el cliente proporcione su nombre y teléfono para agendar una cita o expresar interés formal en una propiedad.",
        parameters: {
          type: "OBJECT",
          properties: {
            clientName: {
              type: "STRING",
              description: "Nombre completo del cliente interesado"
            },
            phone: {
              type: "STRING",
              description: "Número de teléfono de contacto (preferiblemente con WhatsApp)"
            },
            clientEmail: {
              type: "STRING",
              description: "Correo electrónico opcional del cliente"
            },
            propertyRef: {
              type: "NUMBER",
              description: "El número de referencia único de la propiedad (ej: 40 o 42)"
            },
            appointmentDate: {
              type: "STRING",
              description: "Fecha opcional de la cita en formato YYYY-MM-DD (ej: 2026-05-30)"
            },
            appointmentTime: {
              type: "STRING",
              description: "Hora opcional de la cita en formato HH:MM (ej: 14:30)"
            },
            notes: {
              type: "STRING",
              description: "Notas o condiciones especiales de la visita"
            }
          },
          required: ["clientName", "phone", "propertyRef"]
        }
      },
      {
        name: "modificar_solicitud_visita",
        description: "Modifica o cancela una solicitud de visita existente en el CRM usando el número de teléfono y nombre del cliente. Debe llamarse cuando el cliente pida cancelar o cambiar la fecha/hora de su cita.",
        parameters: {
          type: "OBJECT",
          properties: {
            clientName: {
              type: "STRING",
              description: "Nombre completo del cliente"
            },
            phone: {
              type: "STRING",
              description: "Número de teléfono de contacto usado al agendar"
            },
            action: {
              type: "STRING",
              description: "Acción a realizar: 'cancel' para cancelar la cita, 'reschedule' para cambiar fecha/hora, 'confirm' para confirmar la cita, 'done' para finalizar/marcar como realizada la cita."
            },
            newDate: {
              type: "STRING",
              description: "Nueva fecha en formato YYYY-MM-DD (solo si action es 'reschedule')"
            },
            newTime: {
              type: "STRING",
              description: "Nueva hora en formato HH:MM (solo si action es 'reschedule')"
            }
          },
          required: ["clientName", "phone", "action"]
        }
      },
      {
        name: "consultar_visitas_cliente",
        description: "Busca citas de visitas activas (pendientes, confirmadas o realizadas) registradas en el CRM o Agenda usando el número de teléfono del cliente.",
        parameters: {
          type: "OBJECT",
          properties: {
            phone: {
              type: "STRING",
              description: "Número de teléfono del cliente usado al agendar"
            }
          },
          required: ["phone"]
        }
      }
    ]
  }
];

async function findBestCityMatch(inputCity: string, supabaseClient: any, company_id: string): Promise<string> {
  if (!inputCity || inputCity.trim().length === 0) return inputCity;
  
  const cleanInput = inputCity.trim().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  
  // Get all unique cities with properties for this company
  const { data } = await supabaseClient
    .from('properties')
    .select('city')
    .eq('company_id', company_id);
    
  if (!data || data.length === 0) return inputCity;
  
  const uniqueCities = Array.from(new Set(data.map((p: any) => p.city).filter(Boolean))) as string[];
  
  // 1. Exact normalized match (ignoring accents & capitalization)
  for (const city of uniqueCities) {
    const cleanCity = city.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    if (cleanCity === cleanInput || cleanCity.includes(cleanInput) || cleanInput.includes(cleanCity)) {
      return city;
    }
  }
  
  // 2. Vocal-masked match (substituting all vowels by '*' to tolerate typos like "lecharia" instead of "lecheria")
  const vocalMask = (s: string) => s.replace(/[aeiou]/g, '*');
  const maskedInput = vocalMask(cleanInput);
  
  for (const city of uniqueCities) {
    const cleanCity = city.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    if (vocalMask(cleanCity) === maskedInput) {
      return city;
    }
  }
  
  return inputCity;
}

async function handleFunctionCall(functionCall: any, supabaseClient: any, company: any, baseUrl: string, locale: string) {
  const company_id = company?.id;
  if (functionCall.name === 'buscar_propiedades') {
    const args = functionCall.args || {};
    
    // Join with property_details to get bedrooms, bathrooms, area, and all amenities
    let query = supabaseClient.from('properties').select(`
      id, title, description, price, address, city, state, type, operation_type, status, ref_number,
      property_details!inner (
        bedrooms, bathrooms, area_m2, parking_spaces, floors,
        has_air_con, has_extra_storage, has_garden, is_furnished,
        has_pool, has_terrace, has_balcony, has_patio, has_garage,
        has_elevator, has_security, has_power_generator, has_water_tank,
        delivery_status, floor_level, has_storage_office_area
      )
    `).eq('company_id', company_id);

    // Apply filters based on function arguments
    if (args.operationType) query = query.ilike('operation_type', `%${args.operationType}%`);
    if (args.propertyType) query = query.ilike('type', `%${args.propertyType}%`);
    if (args.city) {
      const matchedCity = await findBestCityMatch(args.city, supabaseClient, company_id);
      query = query.ilike('city', `%${matchedCity}%`);
    }
    if (args.maxPrice) query = query.lte('price', args.maxPrice);

    // Filters on nested property_details
    if (args.minBedrooms) query = query.gte('property_details.bedrooms', args.minBedrooms);
    if (args.bathrooms) query = query.gte('property_details.bathrooms', args.bathrooms);
    if (args.parkingSpaces) query = query.gte('property_details.parking_spaces', args.parkingSpaces);
    if (args.minArea) query = query.gte('property_details.area_m2', args.minArea);
    if (args.deliveryStatus) query = query.ilike('property_details.delivery_status', `%${args.deliveryStatus}%`);
    if (args.floorLevel) query = query.ilike('property_details.floor_level', `%${args.floorLevel}%`);

    // Boolean features
    if (args.isFurnished !== undefined) query = query.eq('property_details.is_furnished', args.isFurnished);
    if (args.hasPool !== undefined) query = query.eq('property_details.has_pool', args.hasPool);
    if (args.hasAirCon !== undefined) query = query.eq('property_details.has_air_con', args.hasAirCon);
    if (args.hasPowerGenerator !== undefined) query = query.eq('property_details.has_power_generator', args.hasPowerGenerator);
    if (args.hasWaterTank !== undefined) query = query.eq('property_details.has_water_tank', args.hasWaterTank);
    if (args.hasSecurity !== undefined) query = query.eq('property_details.has_security', args.hasSecurity);
    if (args.hasElevator !== undefined) query = query.eq('property_details.has_elevator', args.hasElevator);

    // Multi-column free text search
    if (args.searchQuery) {
      query = query.or(`title.ilike.%${args.searchQuery}%,description.ilike.%${args.searchQuery}%,address.ilike.%${args.searchQuery}%`);
    }

    query = query.limit(5);

    const { data, error } = await query;
    if (error) {
      console.error('DB Error:', error);
      return { error: error.message };
    }
    
    if (!data || data.length === 0) {
      return { message: "No se encontraron propiedades con esos filtros." };
    }
    
    // Inject public_link
    return data.map((p: any) => ({
      ...p,
      public_link: `${baseUrl}${String(p.ref_number).padStart(3, '0')}`
    }));
  }
  
  if (functionCall.name === 'detalle_propiedad') {
    const args = functionCall.args || {};
    if (!args.refNumber) return { error: "Falta refNumber" };
    
    const { data, error } = await supabaseClient.from('properties').select(`
      *,
      property_details (*)
    `).eq('company_id', company_id).eq('ref_number', args.refNumber).single();

    if (error) return { error: error.message };
    if (!data) return { message: "Propiedad no encontrada." };
    
    // Inject public_link
    return {
      ...data,
      public_link: `${baseUrl}${String(data.ref_number).padStart(3, '0')}`
    };
  }

  if (functionCall.name === 'generar_link_propiedad') {
    const args = functionCall.args || {};
    if (!args.refNumber) return { error: "Falta refNumber" };
    return { link: `${baseUrl}${String(args.refNumber).padStart(3, '0')}` };
  }

  if (functionCall.name === 'registrar_solicitud_visita') {
    const args = functionCall.args || {};
    if (!args.clientName || !args.phone || !args.propertyRef) {
      return { error: "Faltan datos obligatorios (nombre, teléfono o referencia de la propiedad)" };
    }

    // Initialize supabaseAdmin with service role key to bypass RLS SELECT limitations for anonymous/public visitors
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Parse propertyRef defensively to ensure it is treated as a number
    const refNum = typeof args.propertyRef === 'string' ? parseInt(args.propertyRef, 10) : args.propertyRef;

    // 1. Find the property by its ref_number to get its UUID and listing_agent_id (can use public supabaseClient or admin)
    const { data: property, error: propError } = await supabaseClient
      .from('properties')
      .select('id, title, listing_agent_id')
      .eq('company_id', company_id)
      .eq('ref_number', refNum)
      .single();

    if (propError || !property) {
      console.error('Property search error in CRM registration:', propError);
      return { error: `No se encontró la propiedad con la Ref. ${args.propertyRef}` };
    }

    // 1.5. CHECK AVAILABILITY: Verify if there is already a CONFIRMED appointment for the same property or agent on that date/time
    if (args.appointmentDate && args.appointmentTime) {
      const formattedTime = args.appointmentTime.includes(':')
        ? (args.appointmentTime.split(':').length === 2 ? `${args.appointmentTime}:00` : args.appointmentTime)
        : args.appointmentTime;

      // Fetch all confirmed appointments of that day for this agent or property to build busy slots list
      const { data: dayAppts, error: checkError } = await supabaseAdmin
        .from('budget_requests')
        .select('appointment_time, property_list, assigned_agent_id')
        .eq('company_id', company_id)
        .eq('appointment_date', args.appointmentDate)
        .eq('appointment_status', 'confirmed');

      const busyTimes: string[] = [];
      if (!checkError && dayAppts) {
        for (const appt of dayAppts) {
          const matchesAgent = property.listing_agent_id && appt.assigned_agent_id === property.listing_agent_id;
          const matchesProperty = Array.isArray(appt.property_list) && appt.property_list.includes(property.id);
          if (matchesAgent || matchesProperty) {
            const t = appt.appointment_time?.substring(0, 5);
            if (t) busyTimes.push(t);
          }
        }
      }

      if (busyTimes.includes(formattedTime.substring(0, 5))) {
        return { 
          success: false, 
          conflict: true,
          busy_hours: busyTimes,
          message: `Conflicto de horario: El bloque del ${args.appointmentDate} a las ${args.appointmentTime} ya tiene una cita confirmada para este agente o propiedad. Las siguientes horas del mismo día ya están ocupadas: ${busyTimes.join(', ')}. Por favor, infórmale amablemente al cliente que ese horario ya está reservado y sugiérele proactivamente horarios alternativos libres en el mismo día.`
        };
      }
    }

    // 2. Format the property list JSON array
    const propertyList = [property.id];

    // 3. Prepare the insert data matching the schema of public.budget_requests
    const insertData: any = {
      company_id: company_id,
      client_name: args.clientName,
      phone: args.phone,
      client_email: args.clientEmail || 'no-email@local', // Constraint de la tabla budget_requests para la app
      property_list: propertyList,
      notes: args.notes || 'Registrado automáticamente por la Asistente de IA Ava.',
      status: (args.appointmentDate || args.appointmentTime) ? 'responded' : 'pending', // Set status to responded immediately when appointment is created!
      is_appointment: !!(args.appointmentDate || args.appointmentTime),
      assigned_agent_id: property.listing_agent_id || null,
      source: 'ava'
    };

    if (args.appointmentDate) {
      insertData.appointment_date = args.appointmentDate;
    }
    if (args.appointmentTime) {
      // Format time as HH:MM:00 if it only has HH:MM
      insertData.appointment_time = args.appointmentTime.includes(':')
        ? (args.appointmentTime.split(':').length === 2 ? `${args.appointmentTime}:00` : args.appointmentTime)
        : args.appointmentTime;
      insertData.appointment_status = 'pending'; // lowercase pending for the Agenda/Calendar screen dropdown items list
    }

    // 4. Insert the row into budget_requests using supabaseAdmin so select().single() succeeds
    const { data, error: insertError } = await supabaseAdmin
      .from('budget_requests')
      .insert(insertData)
      .select()
      .single();

    if (insertError) {
      console.error('Error inserting budget_request/appointment:', insertError);
      return { error: `Error al guardar en el CRM: ${insertError.message}` };
    }

    // 5. Send notification email via edge function
    try {
      let agentEmail = null;
      if (property.listing_agent_id) {
        const { data: agentData } = await supabaseAdmin
          .from('profiles')
          .select('email')
          .eq('id', property.listing_agent_id)
          .single();
        if (agentData) agentEmail = agentData.email;
      }

      await supabaseAdmin.functions.invoke('send-budget-email', {
        body: {
          name: args.clientName,
          email: args.clientEmail || null,
          phone: args.phone,
          notes: args.notes || 'Registrado automáticamente por la Asistente de IA Ava.',
          propertyIds: propertyList,
          locale: locale || 'es',
          companyEmail: company?.contact_email || null,
          companyName: company?.name || 'Alveo Real Estate',
          primaryColor: company?.primary_color,
          secondaryColor: company?.secondary_color,
          agentEmail: agentEmail
        }
      });
      console.log('Email notification triggered');
    } catch (e) {
      console.error('Failed to trigger email notification', e);
    }

    return { 
      success: true, 
      message: "Solicitud registrada con éxito en el CRM de Alveo.",
      id: data.id,
      isAppointment: data.is_appointment,
      appointmentDate: data.appointment_date,
      appointmentTime: data.appointment_time,
      propertyTitle: property.title
    };
  }

  if (functionCall.name === 'consultar_visitas_cliente') {
    const args = functionCall.args || {};
    if (!args.phone) return { error: "Falta phone" };

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: allVisits, error } = await supabaseAdmin
      .from('budget_requests')
      .select('id, client_name, phone, client_email, appointment_date, appointment_time, appointment_status, status, is_appointment, property_list, assigned_agent_id, notes, sent_at')
      .eq('company_id', company_id);

    if (error) return { error: error.message };

    const searchDigits = args.phone.replace(/\D/g, '');
    const visits = (allVisits || []).filter((v: any) => {
      const dbDigits = (v.phone || '').replace(/\D/g, '');
      return dbDigits === searchDigits || dbDigits.endsWith(searchDigits) || searchDigits.endsWith(dbDigits);
    });

    // Sort visits newest first based on sent_at
    visits.sort((a: any, b: any) => {
      const aTime = a.sent_at ? new Date(a.sent_at).getTime() : 0;
      const bTime = b.sent_at ? new Date(b.sent_at).getTime() : 0;
      return bTime - aTime;
    });

    if (error) return { error: error.message };
    if (!visits || visits.length === 0) {
      return { success: false, message: "No se encontraron citas o solicitudes de visitas activas bajo ese número de teléfono." };
    }

    // Translate property ids to titles and references for Ava
    const results = [];
    for (const v of visits) {
      let propertyInfo = "No especificado";
      if (Array.isArray(v.property_list) && v.property_list.length > 0) {
        const { data: prop } = await supabaseAdmin
          .from('properties')
          .select('title, ref_number')
          .eq('id', v.property_list[0])
          .single();
        if (prop) {
          propertyInfo = `Ref: ${String(prop.ref_number).padStart(3, '0')} - ${prop.title}`;
        }
      }
      
      let agentName = "No asignado";
      if (v.assigned_agent_id) {
        const { data: profile } = await supabaseAdmin
          .from('profiles')
          .select('full_name')
          .eq('id', v.assigned_agent_id)
          .single();
        if (profile) agentName = profile.full_name;
      }

      results.push({
        id: v.id,
        client_name: v.client_name,
        phone: v.phone,
        client_email: v.client_email && v.client_email.endsWith('@local') ? '—' : v.client_email,
        appointment_date: v.appointment_date || '—',
        appointment_time: v.appointment_time || '—',
        appointment_status: v.appointment_status || '—',
        status: v.status,
        is_appointment: v.is_appointment,
        property: propertyInfo,
        agent: agentName,
        notes: v.notes
      });
    }

    return { success: true, visits: results };
  }

  if (functionCall.name === 'modificar_solicitud_visita') {
    const args = functionCall.args || {};
    if (!args.clientName || !args.phone || !args.action) {
      return { error: "Faltan datos obligatorios (nombre, teléfono o acción)" };
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Find the most recent active budget_request for this phone/name
    const { data: allReqs, error: reqError } = await supabaseAdmin
      .from('budget_requests')
      .select('id, appointment_date, appointment_time, appointment_status, property_list, assigned_agent_id, status, client_name, client_email, phone, notes, sent_at')
      .eq('company_id', company_id)
      .in('status', ['pending', 'responded']);

    if (reqError) return { error: reqError.message };

    const searchDigits = args.phone.replace(/\D/g, '');
    const requests = (allReqs || []).filter((r: any) => {
      const dbDigits = (r.phone || '').replace(/\D/g, '');
      return dbDigits === searchDigits || dbDigits.endsWith(searchDigits) || searchDigits.endsWith(dbDigits);
    });

    // Sort requests newest first based on sent_at
    requests.sort((a: any, b: any) => {
      const aTime = a.sent_at ? new Date(a.sent_at).getTime() : 0;
      const bTime = b.sent_at ? new Date(b.sent_at).getTime() : 0;
      return bTime - aTime;
    });

    if (reqError || !requests || requests.length === 0) {
      return { success: false, message: "No se encontró ninguna solicitud de visita activa registrada bajo ese número de teléfono y nombre." };
    }

    const request = requests[0];

    if (args.action === 'cancel') {
      const { error: updError } = await supabaseAdmin
        .from('budget_requests')
        .update({ status: 'rejected', appointment_status: 'cancelled', notes: 'Cancelado automáticamente por Ava a petición del cliente.' })
        .eq('id', request.id);

      if (updError) return { error: `Error al cancelar: ${updError.message}` };
      
      // Trigger notification email to agent
      await triggerUpdateEmail(supabaseAdmin, company, locale, request, 'cancel', null, null);

      return { success: true, message: "Cita y solicitud canceladas con éxito." };
    }

    if (args.action === 'confirm') {
      const { error: updError } = await supabaseAdmin
        .from('budget_requests')
        .update({ 
          status: 'responded', 
          appointment_status: 'confirmed', 
          notes: request.notes ? `${request.notes}\nConfirmado automáticamente por Ava a petición del cliente.` : 'Confirmado automáticamente por Ava a petición del cliente.'
        })
        .eq('id', request.id);

      if (updError) return { error: `Error al confirmar: ${updError.message}` };
      
      // Trigger notification email to agent
      await triggerUpdateEmail(supabaseAdmin, company, locale, request, 'confirm', null, null);

      return { success: true, message: "Cita confirmada con éxito." };
    }

    if (args.action === 'done') {
      const { error: updError } = await supabaseAdmin
        .from('budget_requests')
        .update({ 
          status: 'responded', 
          appointment_status: 'done', 
          notes: request.notes ? `${request.notes}\nFinalizada / Realizada automáticamente por Ava.` : 'Finalizada / Realizada automáticamente por Ava.'
        })
        .eq('id', request.id);

      if (updError) return { error: `Error al marcar como realizada: ${updError.message}` };
      
      // Trigger notification email to agent
      await triggerUpdateEmail(supabaseAdmin, company, locale, request, 'done', null, null);

      return { success: true, message: "Cita marcada como finalizada/realizada con éxito." };
    }

    if (args.action === 'reschedule') {
      if (!args.newDate || !args.newTime) return { error: "Para reprogramar, debes proporcionar newDate y newTime." };

      const formattedTime = args.newTime.includes(':')
        ? (args.newTime.split(':').length === 2 ? `${args.newTime}:00` : args.newTime)
        : args.newTime;

      // Anti-collision logic: fetch confirmed times for that day
      const { data: dayAppts, error: checkError } = await supabaseAdmin
        .from('budget_requests')
        .select('appointment_time, property_list, assigned_agent_id')
        .eq('company_id', company_id)
        .eq('appointment_date', args.newDate)
        .eq('appointment_status', 'confirmed');

      const busyTimes: string[] = [];
      if (!checkError && dayAppts) {
        for (const appt of dayAppts) {
          const matchesAgent = request.assigned_agent_id && appt.assigned_agent_id === request.assigned_agent_id;
          const matchesProperty = Array.isArray(appt.property_list) && Array.isArray(request.property_list) &&
            appt.property_list.some((pid:any) => request.property_list.includes(pid));
          if (matchesAgent || matchesProperty) {
            const t = appt.appointment_time?.substring(0, 5);
            if (t) busyTimes.push(t);
          }
        }
      }

      if (busyTimes.includes(formattedTime.substring(0, 5))) {
        return { 
          success: false, 
          conflict: true,
          busy_hours: busyTimes,
          message: `Conflicto de horario: El bloque del ${args.newDate} a las ${args.newTime} ya está ocupado para esa propiedad/agente. Las siguientes horas de ese día ya están ocupadas: ${busyTimes.join(', ')}. Sugiere proactivamente horarios libres.`
        };
      }

      const { error: updError } = await supabaseAdmin
        .from('budget_requests')
        .update({ 
          appointment_date: args.newDate, 
          appointment_time: formattedTime, 
          appointment_status: 'pending',
          status: 'responded', // Keep CRM lead as responded
          is_appointment: true
        })
        .eq('id', request.id);

      if (updError) return { error: `Error al reprogramar: ${updError.message}` };
      
      // Trigger notification email to agent
      await triggerUpdateEmail(supabaseAdmin, company, locale, request, 'reschedule', args.newDate, formattedTime);

      return { success: true, message: "Cita reprogramada con éxito en la nueva fecha y hora." };
    }

    return { error: "Acción no reconocida" };
  }

  return { error: 'Unknown function' };
}

async function triggerUpdateEmail(
  supabaseAdmin: any, company: any, locale: string, 
  request: any, updateType: string, newDate: string | null, newTime: string | null
) {
  try {
    let propTitle = "Inmueble Alveo";
    const propertyList = request.property_list;
    if (Array.isArray(propertyList) && propertyList.length > 0) {
      const { data: prop } = await supabaseAdmin
        .from('properties')
        .select('title, ref_number')
        .eq('id', propertyList[0])
        .single();
      if (prop) {
        propTitle = `Ref: ${String(prop.ref_number).padStart(3, '0')} - ${prop.title}`;
      }
    }

    let agentEmail = null;
    if (request.assigned_agent_id) {
      const { data: agentProfile } = await supabaseAdmin
        .from('profiles')
        .select('email')
        .eq('id', request.assigned_agent_id)
        .single();
      if (agentProfile) agentEmail = agentProfile.email;
    }

    await supabaseAdmin.functions.invoke('send-budget-email', {
      body: {
        name: request.client_name,
        email: request.client_email && request.client_email.endsWith('@local') ? null : request.client_email,
        phone: request.phone,
        notes: request.notes || '',
        propertyIds: propertyList,
        locale: locale || 'es',
        companyEmail: company?.contact_email || null,
        companyName: company?.name || 'Alveo Real Estate',
        primaryColor: company?.primary_color,
        secondaryColor: company?.secondary_color,
        agentEmail: agentEmail,
        isUpdate: true,
        updateType: updateType,
        appointmentDate: newDate || request.appointment_date,
        appointmentTime: newTime || request.appointment_time
      }
    });
    console.log('Update email notification sent to agent successfully');
  } catch (e) {
    console.error('Failed to trigger update email notification:', e);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { message, type, audio_base64, mime_type, company_id, locale, history, ai_model } = await req.json();

    if (!company_id) {
      return new Response(JSON.stringify({ error: 'company_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Auth context (respects RLS)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    
    // Fetch company info for prompt using supabaseAdmin to bypass RLS SELECT limitations on company details
    const { data: company } = await supabaseAdmin
      .from('companies')
      .select('id, name, domain, contact_email, primary_color, secondary_color')
      .eq('id', company_id)
      .single();
      
    const companyName = company?.name || 'Alveo';
    const subdomain = company?.domain ? company.domain.split('.')[0] : 'demo';
    const baseUrl = `https://${subdomain}.alveo.fyi/ref`;
    
    const isEn = locale === 'en';

    // ZERO-COST MOCK SIMULATOR MODE INTERCEPTOR
    if (ai_model === 'mock-test') {
      console.log('Modo Simulador de Pruebas activo.');

      if (type === 'audio') {
        const audioReply = isEn
          ? "Hello! I am Ava, your AI virtual assistant. Voice notes are not supported in this offline mode. Please type your message so I can search properties for you!"
          : "¡Hola! Soy Ava, tu asistente virtual. En este momento las notas de voz no están disponibles. Por favor, escríbeme un mensaje de texto para ayudarte a buscar propiedades.";
        return new Response(JSON.stringify({ reply: audioReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const textMessage = message || '';
      const formatPrice = (val: number) => `$${Math.round(val).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}`;

      // --- APPOINTMENT BOOKING INTENT SIMULATOR ---
      if (/visitar|cita|agendar|contacto|interes|interés/i.test(textMessage) && (/\d{7,}/.test(textMessage) || /@/.test(textMessage))) {
        console.log('Simulador: Detectado intento de agendamiento/contacto en mock-test.');
        
        let propertyRef = 40; // Default fallback
        let refMatch = textMessage.match(/ref\s*(\d+)/i);
        if (refMatch) {
          propertyRef = parseInt(refMatch[1], 10);
        }

        const clientName = "Cliente Alveo";
        const phoneMatch = textMessage.match(/\+?\d[\d\s\-]{6,}\d/);
        const phone = phoneMatch ? phoneMatch[0].trim() : "desconocido";

        const bookingReply = isEn
          ? `¡Excellent! I have successfully registered your interest for property **Ref. ${String(propertyRef).padStart(3, '0')}** in our CRM.\n\n` +
            `* **Client Name:** ${clientName}\n` +
            `* **Phone Number:** ${phone}\n` +
            `* **Status:** Visit Request Pending Confirmation\n\n` +
            `A real estate agent will contact you shortly to schedule and confirm your appointment. Thank you for choosing Alveo!`
          : `¡Excelente! He registrado tu interés para la propiedad **Ref. ${String(propertyRef).padStart(3, '0')}** con éxito en nuestro CRM.\n\n` +
            `* **Nombre:** ${clientName}\n` +
            `* **Teléfono:** ${phone}\n` +
            `* **Estado:** Solicitud de Visita Pendiente de Confirmación\n\n` +
            `Un agente inmobiliario se pondrá en contacto contigo muy pronto para coordinar y confirmar el día y la hora de tu cita. ¡Gracias por confiar en Alveo!`;

        return new Response(JSON.stringify({ reply: bookingReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // --- APPOINTMENT MODIFICATION INTENT SIMULATOR ---
      if (/cancelar|reprogramar|cambiar|modificar|confirmar|finalizar|realizada|terminada|done/i.test(textMessage) && (/\d{7,}/.test(textMessage) || /@/.test(textMessage))) {
        console.log('Simulador: Detectado intento de modificacion/cancelacion/confirmacion/finalizacion en mock-test.');
        
        let action = 'reprogramada';
        if (/cancelar/i.test(textMessage)) action = 'cancelada';
        if (/confirmar/i.test(textMessage)) action = 'confirmada';
        if (/finalizar|realizada|terminada|done/i.test(textMessage)) action = 'finalizada/realizada';
        
        const modReply = isEn
          ? `I have successfully simulated the modification of your appointment. Status: **${action.toUpperCase()}**.\nNote: This is a simulation.`
          : `He simulado exitosamente la modificación de tu cita. Nuevo estado: **${action.toUpperCase()}**.\nNota: Esta es una simulación.`;

        return new Response(JSON.stringify({ reply: modReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // --- APPOINTMENT READ INTENT SIMULATOR ---
      if (/consultar|ver\s*cita|tengo\s*cita|mis\s*citas/i.test(textMessage) && (/\d{7,}/.test(textMessage) || /@/.test(textMessage))) {
        console.log('Simulador: Detectado intento de consulta en mock-test.');
        const consultReply = isEn
          ? `I found 1 active appointment registered under your phone:\n\n` +
            `* **Client Name:** Cliente Alveo\n` +
            `* **Property:** Ref. 040 - Villa Linda en Anaco\n` +
            `* **Date:** 2026-05-30\n` +
            `* **Time:** 14:30\n` +
            `* **Status:** CONFIRMED\n\n` +
            `If you wish to reschedule or cancel it, let me know!`
          : `He encontrado 1 cita activa registrada bajo tu número de teléfono:\n\n` +
            `* **Cliente:** Cliente Alveo\n` +
            `* **Inmueble:** Ref. 040 - Villa Linda en Anaco\n` +
            `* **Fecha:** 2026-05-30\n` +
            `* **Hora:** 14:30\n` +
            `* **Estado:** CONFIRMADA\n\n` +
            `Si deseas reprogramarla o cancelarla, ¡avísame!`;
        return new Response(JSON.stringify({ reply: consultReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Check for property details via ref number, e.g. ref041, 041, 1024
      let refMatch = textMessage.match(/ref\s*(\d+)/i) || textMessage.match(/\b(\d{1,4})\b/);
      if (refMatch) {
        const refNumber = parseInt(refMatch[1], 10);
        console.log('Simulador: Buscando propiedad por ref_number:', refNumber);
        const result = await handleFunctionCall({ name: 'detalle_propiedad', args: { refNumber } }, supabaseClient, company, baseUrl, locale);
        
        if (result.error || result.message) {
          const notFoundReply = isEn
            ? `Property Ref. ${String(refNumber).padStart(3, '0')} was not found in the database. Please try another reference number.`
            : `No encontré la propiedad con la Ref. ${String(refNumber).padStart(3, '0')} en la base de datos. Por favor, intenta con otro número de referencia.`;
          return new Response(JSON.stringify({ reply: notFoundReply }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Format property details
        const priceFormatted = result.price ? formatPrice(result.price) : 'N/A';
        const areaFormatted = result.property_details?.area_m2 ? `${result.property_details.area_m2} m²` : 'N/A';
        const bedrooms = result.property_details?.bedrooms ?? 'N/A';
        const bathrooms = result.property_details?.bathrooms ?? 'N/A';

        const detailsReply = isEn
          ? `Here are the details of **Ref. ${String(result.ref_number).padStart(3, '0')}**:\n\n` +
            `* **Title:** ${result.title}\n` +
            `* **Price:** ${priceFormatted}\n` +
            `* **Operation:** ${result.operation_type}\n` +
            `* **Type:** ${result.type}\n` +
            `* **Location:** ${result.city || ''}, ${result.state || ''}\n` +
            `* **Specs:** ${bedrooms} beds | ${bathrooms} baths | ${areaFormatted}\n` +
            `* **Description:** ${result.description || ''}\n\n` +
            `[Ver fotos y detalles](${result.public_link})`
          : `Aquí tienes los detalles de la propiedad **Ref. ${String(result.ref_number).padStart(3, '0')}**:\n\n` +
            `* **Título:** ${result.title}\n` +
            `* **Precio:** ${priceFormatted}\n` +
            `* **Operación:** ${result.operation_type}\n` +
            `* **Tipo:** ${result.type}\n` +
            `* **Ubicación:** ${result.city || ''}, ${result.state || ''}\n` +
            `* **Distribución:** ${bedrooms} habs | ${bathrooms} baños | ${areaFormatted}\n` +
            `* **Descripción:** ${result.description || ''}\n\n` +
            `[Ver fotos y detalles](${result.public_link})`;

        return new Response(JSON.stringify({ reply: detailsReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Keyword matching
      const args: any = {};
      if (/villa|casa|house/i.test(textMessage)) args.propertyType = 'Casa';
      if (/apto|apartamento|apartment/i.test(textMessage)) args.propertyType = 'Apartamento';
      if (/local|comercio|commercial/i.test(textMessage)) args.propertyType = 'Local';
      if (/terreno|solar|land/i.test(textMessage)) args.propertyType = 'Terreno';
      if (/galp[oó]n|warehouse/i.test(textMessage)) args.propertyType = 'Galpon';
      if (/oficina|office/i.test(textMessage)) args.propertyType = 'Oficina';
      if (/almac[eé]n|dep[oó]sito|storage/i.test(textMessage)) args.propertyType = 'Almacén';
      if (/\[aá]tico|penthouse/i.test(textMessage)) args.propertyType = 'Ático';
      if (/d[uú]plex/i.test(textMessage)) args.propertyType = 'Dúplex';
      if (/loft/i.test(textMessage)) args.propertyType = 'Loft';
      if (/estudio|studio|monoambiente/i.test(textMessage)) args.propertyType = 'Estudio';
      if (/posada|hostel/i.test(textMessage)) args.propertyType = 'Posada';
      if (/hotel/i.test(textMessage)) args.propertyType = 'Hotel';
      if (/tienda|shop/i.test(textMessage)) args.propertyType = 'Tienda';

      if (/alquiler|rent|rentar/i.test(textMessage)) args.operationType = 'Alquiler';
      if (/venta|sale|comprar|buy/i.test(textMessage)) args.operationType = 'Venta';

      // --- EXTRA MOCK FILTERS ---
      if (/amoblado|amueblado|equipado|furnished/i.test(textMessage)) args.isFurnished = true;
      if (/piscina|alberca|pool/i.test(textMessage)) args.hasPool = true;
      if (/aire\s*acondicionado|a\/c|air\s*con|split/i.test(textMessage)) args.hasAirCon = true;
      if (/planta\s*electrica|generador|planta|power\s*gen/i.test(textMessage)) args.hasPowerGenerator = true;
      if (/tanque|pozo|agua/i.test(textMessage)) args.hasWaterTank = true;
      if (/vigilancia|seguridad|security/i.test(textMessage)) args.hasSecurity = true;
      if (/ascensor|elevador|elevator/i.test(textMessage)) args.hasElevator = true;

      if (/obra\s*gris/i.test(textMessage)) args.deliveryStatus = 'Obra gris';
      if (/listo\s*para\s*ocupar|listo\s*para\s*entrar/i.test(textMessage)) args.deliveryStatus = 'Listo para ocupar';

      if (/planta\s*baja/i.test(textMessage)) args.floorLevel = 'Planta baja';
      if (/mezzanina/i.test(textMessage)) args.floorLevel = 'Mezzanina';

      // Extract city if present (e.g. "en Anaco", "in Valencia")
      const words = textMessage.split(/\s+/);
      for (let i = 0; i < words.length - 1; i++) {
        const wordLower = words[i].toLowerCase();
        if (wordLower === 'en' || wordLower === 'in') {
          const potentialCity = words[i + 1].replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, "").trim();
          const exclude = [
            'venta', 'alquiler', 'rent', 'sale', 'la', 'el', 'los', 'las', 'un', 'una', 'inmueble', 'propiedad', 
            'casa', 'villa', 'apto', 'apartamento', 'local', 'terreno', 'galpon', 'galpón', 'oficina', 'almacen', 
            'almacén', 'deposito', 'depósito', 'atico', 'ático', 'penthouse', 'duplex', 'dúplex', 'loft', 
            'estudio', 'posada', 'hotel', 'tienda', 'obra', 'gris', 'piscina', 'planta', 'tanque', 'pozo'
          ];
          if (potentialCity.length > 2 && !exclude.includes(potentialCity.toLowerCase())) {
            args.city = potentialCity;
            break;
          }
        }
      }

      if (args.propertyType || args.operationType || args.city || args.isFurnished || args.hasPool || args.hasPowerGenerator || args.hasWaterTank || args.hasAirCon) {
        console.log('Simulador: Buscando propiedades por filtros:', args);
        const searchResult = await handleFunctionCall({ name: 'buscar_propiedades', args }, supabaseClient, company, baseUrl, locale);

        if (searchResult.error || searchResult.message || !Array.isArray(searchResult) || searchResult.length === 0) {
          const noneFoundReply = isEn
            ? `I couldn't find any properties matching those criteria in the database.`
            : `No encontré propiedades registradas que coincidan con esos criterios de búsqueda en la base de datos.`;
          return new Response(JSON.stringify({ reply: noneFoundReply }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // --- SMART SIMULATOR FILTERING ---
        let processedResults = [...searchResult];

        // 1. Villa filter (prioritize and restrict to villa if 'villa' is in textMessage)
        if (/villa/i.test(textMessage)) {
          const villaFiltered = searchResult.filter((p: any) => 
            (p.title || '').toLowerCase().includes('villa') || 
            (p.description || '').toLowerCase().includes('villa')
          );
          if (villaFiltered.length > 0) {
            processedResults = villaFiltered;
          }
        } else if (/casa|house/i.test(textMessage)) {
          // If searching for "casa" but NOT "villa", filter OUT the villas from the results to keep them distinct!
          const nonVillaFiltered = searchResult.filter((p: any) => 
            !(p.title || '').toLowerCase().includes('villa') && 
            !(p.description || '').toLowerCase().includes('villa')
          );
          if (nonVillaFiltered.length > 0) {
            processedResults = nonVillaFiltered;
          }
        }

        // 2. Pool / Piscina filter (restrict to properties with pools if in textMessage)
        if (/piscina|pool/i.test(textMessage)) {
          const poolFiltered = processedResults.filter((p: any) => 
            (p.title || '').toLowerCase().includes('piscina') || 
            (p.description || '').toLowerCase().includes('piscina')
          );
          if (poolFiltered.length > 0) {
            processedResults = poolFiltered;
          }
        }
        // ---------------------------------

        const listingsList = processedResults.map((p: any) => {
          const priceFormatted = formatPrice(p.price);
          const bedrooms = p.property_details?.bedrooms ?? 'N/A';
          const bathrooms = p.property_details?.bathrooms ?? 'N/A';
          const area = p.property_details?.area_m2 ? `${p.property_details.area_m2} m²` : 'N/A';
          
          return isEn
            ? `* **${p.title}** (Ref. ${String(p.ref_number).padStart(3, '0')})\n` +
              `  Type: ${p.type} | Op: ${p.operation_type} | Price: ${priceFormatted}\n` +
              `  Specs: ${bedrooms} beds | ${bathrooms} baths | ${area}\n` +
              `  [Ver fotos y detalles](${p.public_link})`
            : `* **${p.title}** (Ref. ${String(p.ref_number).padStart(3, '0')})\n` +
              `  Tipo: ${p.type} | Op: ${p.operation_type} | Precio: ${priceFormatted}\n` +
              `  Detalle: ${bedrooms} habs | ${bathrooms} baños | ${area}\n` +
              `  [Ver fotos y detalles](${p.public_link})`;
        }).join('\n\n');

        const listingsReply = isEn
          ? `I found these properties for you:\n\n${listingsList}`
          : `He encontrado estas propiedades en la base de datos:\n\n${listingsList}`;

        return new Response(JSON.stringify({ reply: listingsReply }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Default simulator guide
      const defaultReply = isEn
        ? `Hello! I am Ava, your AI Virtual Assistant.\n\n` +
          `How can I help you today? Try typing:\n` +
          `* **"villas"** or **"apartment"** to search by type.\n` +
          `* **"rent"** or **"sale"** to filter by operation.\n` +
          `* A specific reference number (e.g., **"041"**) to view its detailed description and links.`
        : `¡Hola! Soy Ava, tu Asistente Virtual Inmobiliaria.\n\n` +
          `¿En qué puedo ayudarte hoy? Intenta escribir:\n` +
          `* **"villas"** o **"apartamento"** para buscar por tipo.\n` +
          `* **"alquiler"** o **"venta"** para filtrar por operación.\n` +
          `* Un número de referencia específico (ej. **"041"**) para ver sus fotos y detalles.`;

      return new Response(JSON.stringify({ reply: defaultReply }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Obtener fecha y hora de referencia local en zona horaria de Carlos (GMT-4)
    const utcOffset = -4 * 60; 
    const localTime = new Date(new Date().getTime() + (utcOffset + new Date().getTimezoneOffset()) * 60000);
    const formattedNow = localTime.toLocaleDateString('es-ES', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric', 
      hour: '2-digit', 
      minute: '2-digit' 
    });

    const systemPrompt = `Eres Ava, la asistente virtual de la agencia inmobiliaria ${companyName}.
Fecha y hora de referencia actual en la inmobiliaria: ${formattedNow}.
Tu rol es ayudar a los clientes y agentes a buscar propiedades usando las herramientas disponibles.
Responde siempre en ${isEn ? 'inglés' : 'español'}. Usa Markdown para formatear tu respuesta.
Limítate a la información proporcionada por las herramientas o a respuestas generales corteses.

ORTOGRAFÍA Y GRAMÁTICA:
- Asegúrate de escribir perfectamente todas las palabras en español.
- Nunca escribas "Bienvido" (con error ortográfico). La palabra correcta en español es "Bienvenido" (con 'e' después de la 'v': B-i-e-n-v-e-n-i-d-o).
- Mantén un tono sumamente profesional, pulido y natural.

MUY IMPORTANTE SOBRE FECHAS Y HORAS:
Cuando el usuario indique una fecha u hora de interés para una visita, debes interpretarlas basándote en la fecha de referencia actual (${formattedNow}) y convertirlas estrictamente al formato requerido por la herramienta 'registrar_solicitud_visita':
1. La fecha ('appointmentDate') DEBE estar estrictamente en formato YYYY-MM-DD (ej. '2026-05-30').
   - Si el usuario dice "el viernes", calcula el próximo viernes desde hoy.
   - Si el usuario escribe formatos como dd/MM/yy o MM/dd/yy o textos como '26/05/26' o '26 de mayo', conviértelos correctamente a YYYY-MM-DD.
2. La hora ('appointmentTime') DEBE estar estrictamente en formato de 24 horas HH:MM (ej. '14:30').
   - Traduce formatos AM/PM o lenguaje natural de forma correcta:
     * 11am -> '11:00'
     * 11pm -> '23:00'
     * 4pm -> '16:00'
     * 12m -> '12:00'
3. Al solicitar la fecha y la hora al usuario, debes guiarlo de forma amigable e indicarle ejemplos explícitos de los formatos que puede ingresar en tu mensaje. Por ejemplo:
   - En español: "(por ejemplo: 28/05/26 o el jueves a las 4pm / 11pm(23:00))"
   - En inglés: "(for example: 05/28/26 or Thursday at 4pm / 11pm)"
   Esto asegura que el usuario comprenda que puede usar formatos tradicionales o lenguaje natural.

MUY IMPORTANTE SOBRE GESTIÓN DE CITAS (CRUD):
1. CONSULTA DE CITAS: Si el usuario te pregunta por sus citas agendadas, debes usar la herramienta 'consultar_visitas_cliente' pasándole su número de teléfono. Esto te permitirá responderle con precisión el inmueble, la fecha, la hora y el estado de su cita.
2. MODIFICACIONES Y CONFIRMACIONES: Si solicita cancelar, reprogramar o confirmar una cita, primero asegúrate de tener su nombre y teléfono (usando 'consultar_visitas_cliente' para verificar si es necesario), y luego invoca 'modificar_solicitud_visita' pasándole esos datos y la acción ('cancel', 'reschedule' o 'confirm').
3. FINALIZACIÓN (Agente/Admin): Si el usuario es un agente o administrador y te pide marcar la cita como realizada o finalizada, usa la herramienta 'modificar_solicitud_visita' con la acción 'done'.
4. MITIGACIÓN DE CONFLICTOS DE HORARIO: Si al agendar o reprogramar el sistema devuelve que el horario está ocupado ('conflict: true'), analiza la lista de 'busy_hours' devuelta para ese día y confiésale amablemente al cliente qué horas están reservadas, sugiriéndole de forma proactiva horarios alternativos libres en el mismo día.

MUY IMPORTANTE SOBRE LOS LINKS Y FOTOS:
Cuando el usuario te pida "ver fotos", "ver más detalles" o te pregunte por una propiedad, SIEMPRE debes incluir el link público de la propiedad en tu respuesta usando formato Markdown: [Ver fotos y detalles]({public_link}).
Los resultados de las herramientas ya incluyen el campo 'public_link', úsalo directamente.`;

    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
    if (!GEMINI_API_KEY) {
      return new Response(JSON.stringify({ error: 'Gemini API Key not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${GEMINI_API_KEY}`;
    
    // Format history for Gemini
    const contents = [];
    if (history && Array.isArray(history)) {
      for (const msg of history) {
        contents.push({
          role: msg.role === 'model' ? 'model' : 'user',
          parts: [{ text: msg.content }]
        });
      }
    }
    
    // Add current message
    if (type === 'audio' && audio_base64 && mime_type) {
      contents.push({
        role: 'user',
        parts: [{ inlineData: { mimeType: mime_type, data: audio_base64 } }]
      });
    } else {
      contents.push({
        role: 'user',
        parts: [{ text: message || 'Hola' }]
      });
    }

    const payload = {
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents: contents,
      tools: tools,
      generationConfig: { temperature: 0.7, maxOutputTokens: 800 }
    };

    let resGemini = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    let geminiData = await resGemini.json();

    if (!resGemini.ok) {
      console.error('Gemini error:', geminiData);
      const errorMsg = geminiData.error?.message || 'Error generating response from AI';
      return new Response(JSON.stringify({ error: errorMsg }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const debugLogs: string[] = [];
    const log = (msg: string) => {
      console.log(msg);
      debugLogs.push(msg);
    };

    let functionCall = geminiData.candidates?.[0]?.content?.parts?.[0]?.functionCall;
    log(`Initial Gemini response: ${JSON.stringify(geminiData.candidates?.[0]?.content || null)}`);

    let iterations = 0;
    while (functionCall && iterations < 3) {
      iterations++;
      log(`Function call detected (iteration ${iterations}): ${functionCall.name} ${JSON.stringify(functionCall.args)}`);
      
      const functionResult = await handleFunctionCall(functionCall, supabaseClient, company, baseUrl, locale);
      log(`Function result: ${JSON.stringify(functionResult)}`);
      
      contents.push(geminiData.candidates[0].content);

      const formattedResponse = Array.isArray(functionResult)
        ? { properties: functionResult }
        : functionResult;

      contents.push({
        role: "user", 
        parts: [{
          functionResponse: {
            name: functionCall.name,
            response: formattedResponse
          }
        }]
      });

      const payload2 = {
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: contents,
        tools: tools,
        generationConfig: { temperature: 0.7, maxOutputTokens: 800 }
      };
      
      resGemini = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload2),
      });
      geminiData = await resGemini.json();

      if (!resGemini.ok) {
        log(`Gemini error (iteration ${iterations}): ${JSON.stringify(geminiData)}`);
        return new Response(JSON.stringify({ error: geminiData.error?.message || `Error generating response after function call in iteration ${iterations}` }), { status: 500, headers: corsHeaders });
      }
      
      log(`Gemini response after function call: ${JSON.stringify(geminiData.candidates?.[0]?.content || null)}`);
      functionCall = geminiData.candidates?.[0]?.content?.parts?.[0]?.functionCall;
    }

    const reply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'No response';
    log(`Final reply: ${reply}`);

    // Insert usage log asynchronously
    supabaseAdmin.from('ai_usage').insert({
      company_id: company_id,
      user_id: user?.id || null,
      visitor_id: req.headers.get('x-client-info') || 'anon',
      input_type: type || 'text',
      input_tokens: geminiData.usageMetadata?.promptTokenCount || 0,
      output_tokens: geminiData.usageMetadata?.candidatesTokenCount || 0,
      model: 'gemini-flash-latest'
    }).then(({ error }) => {
      if (error) console.error('Error tracking usage:', error);
    });

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Function error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
