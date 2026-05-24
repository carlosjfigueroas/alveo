
-- ═══════════════════════════════════════════════════════════════════
-- 1. Habilitar extensión pg_cron
-- ═══════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ═══════════════════════════════════════════════════════════════════
-- 2. Crear la función de verificación de vencimientos
-- ═══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.check_subscription_expirations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count_trial   int := 0;
  v_count_active  int := 0;
BEGIN

  -- ──────────────────────────────────────────────────────────────────
  -- A) Suspender empresas cuyo trial venció
  --    Condición: status = 'trial' AND trial_ends_at < NOW()
  -- ──────────────────────────────────────────────────────────────────
  UPDATE public.companies
  SET
    subscription_status = 'suspended',
    suspended_at        = NOW()
  WHERE
    subscription_status = 'trial'
    AND trial_ends_at IS NOT NULL
    AND trial_ends_at < NOW()
    AND is_demo = false;

  GET DIAGNOSTICS v_count_trial = ROW_COUNT;

  -- ──────────────────────────────────────────────────────────────────
  -- B) Suspender empresas activas cuya suscripción venció
  --    Condición: status = 'active' AND subscription_ends_at < NOW()
  --    Se les da un periodo de gracia de 3 días antes de suspender
  -- ──────────────────────────────────────────────────────────────────
  UPDATE public.companies
  SET
    subscription_status = 'suspended',
    suspended_at        = NOW()
  WHERE
    subscription_status = 'active'
    AND subscription_ends_at IS NOT NULL
    AND subscription_ends_at < (NOW() - INTERVAL '3 days')
    AND is_demo = false;

  GET DIAGNOSTICS v_count_active = ROW_COUNT;

  -- Log en tabla de system events si la hubiera; por ahora usamos RAISE NOTICE
  IF v_count_trial > 0 OR v_count_active > 0 THEN
    RAISE NOTICE '[check_subscription_expirations] Trials suspendidos: %, Activos suspendidos: %', 
      v_count_trial, v_count_active;
  END IF;

END;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- 3. Registrar el Cron Job: ejecutar diariamente a medianoche (UTC)
-- ═══════════════════════════════════════════════════════════════════
SELECT cron.schedule(
  'daily-subscription-check',         -- nombre único del job
  '0 0 * * *',                        -- cada día a las 00:00 UTC
  'SELECT public.check_subscription_expirations();'
);
;
