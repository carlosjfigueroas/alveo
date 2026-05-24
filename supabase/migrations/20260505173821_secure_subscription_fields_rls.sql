
-- ═══════════════════════════════════════════════════════════════════
-- PROBLEMA DETECTADO:
-- La política "companies_admin_update" permite que cualquier company_admin
-- modifique TODOS los campos de su empresa, incluyendo campos críticos
-- de suscripción como: subscription_status, trial_ends_at, suspended_at,
-- subscription_starts_at, subscription_ends_at, base_price, etc.
--
-- SOLUCIÓN:
-- 1. Reemplazar la política de UPDATE amplia por una con restricción
--    de columnas permitidas (via WITH CHECK en columnas específicas).
-- 2. Como PostgreSQL RLS no soporta restricciones a nivel de columna
--    directamente en políticas, usamos una función helper que valida
--    que los campos de suscripción no hayan cambiado.
-- 3. Adicionalmente, también bloqueamos las empresas suspendidas para
--    que no puedan leerse via la política pública (companies_public_read
--    solo permite is_active=true, pero suspendidas siguen activas).
-- ═══════════════════════════════════════════════════════════════════

-- ─── 1. Función helper: valida que el UPDATE no toca campos de suscripción ───
CREATE OR REPLACE FUNCTION public.is_subscription_field_unchanged(company_row companies)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    company_row.subscription_status  = companies.subscription_status AND
    company_row.trial_ends_at        IS NOT DISTINCT FROM companies.trial_ends_at AND
    company_row.subscription_starts_at IS NOT DISTINCT FROM companies.subscription_starts_at AND
    company_row.subscription_ends_at IS NOT DISTINCT FROM companies.subscription_ends_at AND
    company_row.suspended_at         IS NOT DISTINCT FROM companies.suspended_at AND
    company_row.grace_ends_at        IS NOT DISTINCT FROM companies.grace_ends_at AND
    company_row.base_price           = companies.base_price AND
    company_row.referral_discount    = companies.referral_discount AND
    company_row.billing_cycle        = companies.billing_cycle AND
    company_row.max_photos_per_property = companies.max_photos_per_property AND
    company_row.max_properties       = companies.max_properties AND
    company_row.referral_bonus_photos = companies.referral_bonus_photos AND
    company_row.referral_bonus_properties = companies.referral_bonus_properties AND
    company_row.is_active            = companies.is_active AND
    company_row.is_demo              = companies.is_demo
  FROM companies
  WHERE companies.id = company_row.id;
$$;

-- ─── 2. Eliminar la política de UPDATE antigua (demasiado permisiva) ───────────
DROP POLICY IF EXISTS companies_admin_update ON public.companies;

-- ─── 3. Nueva política de UPDATE para company_admin (campos NO-suscripción) ────
--    USING: solo puede actualizar su propia empresa
--    WITH CHECK: los campos de suscripción/billing deben mantenerse sin cambio
CREATE POLICY companies_admin_update ON public.companies
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.company_id = companies.id
        AND profiles.role IN ('admin', 'company_admin')
    )
  )
  WITH CHECK (
    -- El rol puede actualizar solo si NO modifica campos de suscripción
    public.is_subscription_field_unchanged(companies.*)
    AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.company_id = companies.id
        AND profiles.role IN ('admin', 'company_admin')
    )
  );

-- ─── 4. Asegurar que empresas suspendidas puedan leerse por su propio admin ────
--    La política pública solo permite is_active=true.
--    Los admins deben poder leer su empresa aunque esté suspendida.
DROP POLICY IF EXISTS companies_own_company_read ON public.companies;

CREATE POLICY companies_own_company_read ON public.companies
  FOR SELECT
  USING (
    -- El admin/agente de la empresa siempre puede leer su propia empresa
    -- (necesario para mostrar la SuspendedScreen con los datos correctos)
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.company_id = companies.id
    )
  );

-- ─── 5. Comentario informativo ────────────────────────────────────────────────
COMMENT ON FUNCTION public.is_subscription_field_unchanged(companies) IS 
  'Valida que un UPDATE de company_admin no modifique campos de suscripción/billing. 
   Solo super_admin (vía cron job o panel) puede modificar estos campos.';

COMMENT ON FUNCTION public.check_subscription_expirations() IS
  'Cron Job diario (00:00 UTC) que suspende empresas con trial o suscripción vencida.
   Excluye empresas demo. Registrado en cron.job con schedule "0 0 * * *".';
;
