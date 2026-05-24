
-- ============================================================
-- ALVEO MULTI-TENANT: Crear empresas e migrar datos existentes
-- ============================================================

-- 1. Insertar C.C.C.P.R. como primera empresa real
INSERT INTO public.companies (
  name, name_es, name_en, abbr, domain,
  primary_color, secondary_color,
  contact_email, contact_phone, contact_whatsapp,
  instagram_url, facebook_url, telegram_url,
  is_demo, is_active
) VALUES (
  'Grupo Adm. C.C.C.P.R.',
  'Grupo Adm. C.C.C.P.R.',
  'Group Adm. C.C.C.P.R.',
  'cccpr',
  'alveo-cccpr.web.app',
  '#006837',
  '#A64F35',
  'groupadmcccpr.admon@gmail.com',
  '+58 422 702 4040',
  '584227024040',
  'https://instagram.com/groupadmcccpr.admon',
  'https://facebook.com/Groupadmcccpr',
  'https://t.me/Groupadmcccpr',
  FALSE,
  TRUE
) ON CONFLICT (abbr) DO NOTHING;

-- 2. Insertar empresa Demo
INSERT INTO public.companies (
  name, name_es, name_en, abbr, domain,
  primary_color, secondary_color,
  is_demo, is_active
) VALUES (
  'Alveo Demo',
  'Alveo Demo',
  'Alveo Demo',
  'demo',
  'alveo-demo.web.app',
  '#006837',
  '#A64F35',
  TRUE,
  TRUE
) ON CONFLICT (abbr) DO NOTHING;

-- 3. Migrar todos los datos actuales a C.C.C.P.R.
UPDATE public.properties
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

UPDATE public.owners
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

UPDATE public.budget_requests
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

UPDATE public.app_settings
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

UPDATE public.about_us
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

UPDATE public.faqs
  SET company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr')
  WHERE company_id IS NULL;

-- 4. Asignar el usuario administrador actual a C.C.C.P.R.
UPDATE public.profiles
  SET
    company_id = (SELECT id FROM public.companies WHERE abbr = 'cccpr'),
    role = 'company_admin'
  WHERE role = 'admin' AND company_id IS NULL;
;
