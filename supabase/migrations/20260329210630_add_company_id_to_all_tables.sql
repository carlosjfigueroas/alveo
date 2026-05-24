
-- ============================================================
-- ALVEO MULTI-TENANT: Añadir company_id a todas las tablas
-- ============================================================

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.owners
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.budget_requests
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.app_settings
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.about_us
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.faqs
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

-- Índices para agilizar los filtros por empresa
CREATE INDEX IF NOT EXISTS idx_properties_company_id ON public.properties(company_id);
CREATE INDEX IF NOT EXISTS idx_owners_company_id ON public.owners(company_id);
CREATE INDEX IF NOT EXISTS idx_budget_requests_company_id ON public.budget_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_faqs_company_id ON public.faqs(company_id);
;
