import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const body = await req.json();
    const { 
      company_name, contact_name, contact_email, contact_phone, contact_whatsapp,
      password, desired_domain, language, billing_cycle,
      country, state, city, currency_code, currency_symbol, area_unit,
      base_price, logo_url, logo_abbr_url,
      instagram_url, facebook_url, telegram_url,
      primary_color, secondary_color,
      acquisition_channel, referred_alias, referral_email
    } = body;

    // 1. Double check domain availability
    const fullDomain = `${desired_domain}.alveo.fyi`;
    const { data: existing } = await supabaseAdmin
      .from('companies')
      .select('id')
      .or(`domain.eq.${fullDomain},abbr.eq.${desired_domain}`)
      .maybeSingle();
      
    if (existing) throw new Error('Domain or Abbreviation already taken');

    // Fetch global limits to copy into the new company
    const { data: limitSettings } = await supabaseAdmin
      .from('app_settings')
      .select('value')
      .eq('key', 'default_limits')
      .is('company_id', null)
      .maybeSingle();
    
    const maxProps = limitSettings?.value?.max_properties ?? 20;
    const maxPhotos = limitSettings?.value?.max_photos_per_property ?? 10;

    // 2. Create Company
    const { data: company, error: coError } = await supabaseAdmin
      .from('companies')
      .insert({
        name: company_name,
        abbr: desired_domain.toLowerCase(),
        domain: fullDomain,
        contact_name,
        contact_email,
        contact_phone,
        contact_whatsapp,
        language,
        billing_cycle,
        country,
        state,
        city,
        currency_code,
        currency_symbol,
        area_unit,
        base_price,
        logo_url,
        logo_abbr_url,
        instagram_url,
        facebook_url,
        telegram_url,
        primary_color: primary_color || '#006837',
        secondary_color: secondary_color || '#A64F35',
        acquisition_channel,
        referred_by_salesperson: referred_alias,
        referral_email_entered: referral_email,
        is_active: true,
        is_demo: false,
        show_carousel: true,
        carousel_strategy: 'manual',
        show_referral_menu: false,
        show_organic_affiliate: false,
        max_properties: maxProps,
        max_photos_per_property: maxPhotos,
        ai_model: 'mock-test',
        has_ai_agent: true
      })
      .select()
      .single();

    if (coError) throw coError;

    // 3. Create confirmed user in Auth
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: contact_email,
      password: password,
      email_confirm: true,
      user_metadata: { 
        full_name: contact_name,
        role: 'company_admin',
        company_id: company.id
      }
    });

    if (authError) {
      await supabaseAdmin.from('companies').delete().eq('id', company.id);
      throw authError;
    }

    const { error: profError } = await supabaseAdmin
      .from('profiles')
      .upsert({
        id: authUser.user.id,
        full_name: contact_name,
        role: 'company_admin',
        company_id: company.id,
        language: language
      });

    if (profError) throw profError;

    try {
      await supabaseAdmin.functions.invoke('send-subscription-email', {
        body: { 
          type: 'welcome_auto_register', 
          company_id: company.id,
          password: password // Passing password to the email function
        }
      });
    } catch (e) {
      console.error('Email failed:', e);
    }

    return new Response(JSON.stringify({ 
      success: true, 
      company_id: company.id, 
      domain: fullDomain,
      user_id: authUser.user.id 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Registration error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
