
-- ═══════════════════════════════════════════════════════════════════
-- PARTE 1: Recrear vistas con SECURITY INVOKER
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW public.property_likes_count
  WITH (security_invoker = true)
AS
  SELECT property_id, count(*) AS likes_count
  FROM property_likes
  GROUP BY property_id;

CREATE OR REPLACE VIEW public.property_views_count
  WITH (security_invoker = true)
AS
  SELECT property_id, count(*) AS views_count
  FROM property_views
  GROUP BY property_id;

CREATE OR REPLACE VIEW public.top_liked_properties
  WITH (security_invoker = true)
AS
  SELECT
    p.id, p.title, p.description, p.price, p.address, p.type,
    p.operation_type, p.status, p.owner_id, p.admin_id, p.is_public,
    p.created_at, p.ref_number, p.country, p.state, p.city, p.company_id,
    COALESCE(lc.likes_count, 0::bigint) AS likes_count
  FROM properties p
  LEFT JOIN property_likes_count lc ON p.id = lc.property_id
  WHERE p.is_public = true
  ORDER BY COALESCE(lc.likes_count, 0::bigint) DESC, p.created_at DESC;

CREATE OR REPLACE VIEW public.top_viewed_properties
  WITH (security_invoker = true)
AS
  SELECT
    p.id, p.title, p.description, p.price, p.address, p.type,
    p.operation_type, p.status, p.owner_id, p.admin_id, p.is_public,
    p.created_at, p.ref_number, p.country, p.state, p.city, p.company_id,
    p.latitude, p.longitude, pvc.views_count
  FROM properties p
  JOIN property_views_count pvc ON p.id = pvc.property_id
  ORDER BY pvc.views_count DESC;

CREATE OR REPLACE VIEW public.weekly_visitors
  WITH (security_invoker = true)
AS
  SELECT company_id, count(DISTINCT visitor_id) AS visitor_count
  FROM visitor_sessions
  WHERE last_seen_at >= (now() - '7 days'::interval)
  GROUP BY company_id;

-- ═══════════════════════════════════════════════════════════════════
-- PARTE 2: Fijar search_path en funciones con mutable search_path
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, company_id)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client'),
    (NEW.raw_user_meta_data->>'company_id')::uuid
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_property_status_on_sale()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.operation_type IN ('Venta', 'Alquiler') AND NEW.property_id IS NOT NULL THEN
    UPDATE properties
    SET status = CASE WHEN NEW.operation_type = 'Venta' THEN 'Vendido' ELSE 'Alquilado' END
    WHERE id = NEW.property_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.initialize_new_company_content()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  demo_id UUID;
BEGIN
  SELECT id INTO demo_id FROM companies WHERE is_demo = true LIMIT 1;
  IF demo_id IS NOT NULL THEN
    INSERT INTO about_us (company_id, key, value_es, value_en)
    SELECT NEW.id, key,
      REPLACE(value_es, 'NOMBRE EMPRESA', NEW.name),
      REPLACE(value_en, 'NOMBRE EMPRESA', NEW.name)
    FROM about_us WHERE company_id = demo_id;

    INSERT INTO faqs (company_id, question_es, answer_es, question_en, answer_en, sort_order)
    SELECT NEW.id,
      REPLACE(question_es, 'NOMBRE EMPRESA', NEW.name),
      REPLACE(answer_es,   'NOMBRE EMPRESA', NEW.name),
      REPLACE(question_en, 'NOMBRE EMPRESA', NEW.name),
      REPLACE(answer_en,   'NOMBRE EMPRESA', NEW.name),
      sort_order
    FROM faqs WHERE company_id = demo_id;
  END IF;
  RETURN NEW;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- PARTE 3: Añadir guards internos a funciones admin sensibles
-- DROP primero porque tienen DEFAULT en parámetros (incompatible con OR REPLACE)
-- ═══════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.set_user_role(uuid, text, uuid);

CREATE FUNCTION public.set_user_role(
  target_user_id uuid,
  new_role        text,
  new_company_id  uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: super_admin role required';
  END IF;
  UPDATE public.profiles
  SET role = new_role, company_id = new_company_id
  WHERE id = target_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_change_password(user_id uuid, new_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: super_admin role required';
  END IF;
  UPDATE auth.users
  SET encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf'))
  WHERE id = user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_confirm_user_email(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: super_admin role required';
  END IF;
  UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = target_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_user(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('super_admin', 'company_admin', 'admin')
  ) THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;
  DELETE FROM public.profiles WHERE id = target_user_id;
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_subscription_expirations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count_trial  int := 0;
  v_count_active int := 0;
BEGIN
  -- Permite ejecución solo al cron (auth.uid() IS NULL) o a super_admin
  IF auth.uid() IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: super_admin role required';
  END IF;

  UPDATE public.companies
  SET subscription_status = 'suspended', suspended_at = NOW()
  WHERE subscription_status = 'trial'
    AND trial_ends_at IS NOT NULL AND trial_ends_at < NOW()
    AND is_demo = false;
  GET DIAGNOSTICS v_count_trial = ROW_COUNT;

  UPDATE public.companies
  SET subscription_status = 'suspended', suspended_at = NOW()
  WHERE subscription_status = 'active'
    AND subscription_ends_at IS NOT NULL
    AND subscription_ends_at < (NOW() - INTERVAL '3 days')
    AND is_demo = false;
  GET DIAGNOSTICS v_count_active = ROW_COUNT;

  IF v_count_trial > 0 OR v_count_active > 0 THEN
    RAISE NOTICE '[check_subscription_expirations] Trials: %, Activos: %', v_count_trial, v_count_active;
  END IF;
END;
$$;
;
