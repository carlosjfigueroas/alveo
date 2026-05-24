
-- ============================================================
-- ALVEO MULTI-TENANT: FASE 1
-- Crear tabla companies
-- ============================================================

CREATE TABLE IF NOT EXISTS public.companies (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  name_es          TEXT,
  name_en          TEXT,
  abbr             TEXT NOT NULL UNIQUE,
  domain           TEXT NOT NULL UNIQUE,
  logo_url         TEXT,
  primary_color    TEXT NOT NULL DEFAULT '#006837',
  secondary_color  TEXT NOT NULL DEFAULT '#A64F35',
  contact_email    TEXT,
  contact_phone    TEXT,
  contact_whatsapp TEXT,
  instagram_url    TEXT,
  facebook_url     TEXT,
  telegram_url     TEXT,
  is_demo          BOOLEAN NOT NULL DEFAULT FALSE,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: visible públicamente (solo lectura para detectar empresa por dominio)
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "companies_public_read" ON public.companies
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "companies_super_admin_all" ON public.companies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );
;
