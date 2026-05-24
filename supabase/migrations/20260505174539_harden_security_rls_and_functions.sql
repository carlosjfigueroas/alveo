
-- ═══════════════════════════════════════════════════════════════════
-- CORRECCIONES DE SEGURIDAD (Supabase Security Advisor)
-- ═══════════════════════════════════════════════════════════════════

-- ─── 1. TABLAS SIN POLÍTICAS RLS (rls_enabled_no_policy) ────────────────────
-- company_registration_requests: solo super_admin puede leer/gestionar
-- payments: solo super_admin y el company_admin de la empresa pueden leer
-- referrals: la empresa referente y la referida pueden leer; solo sistema puede insertar

-- 1a. company_registration_requests
CREATE POLICY "reg_requests_super_admin_all" ON public.company_registration_requests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  );

-- Permitir INSERT anónimo (es un formulario público de registro)
CREATE POLICY "reg_requests_public_insert" ON public.company_registration_requests
  FOR INSERT WITH CHECK (true);

-- 1b. payments: solo super_admin y company_admin de la empresa
CREATE POLICY "payments_super_admin_all" ON public.payments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  );

CREATE POLICY "payments_company_read" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.company_id = payments.company_id
        AND profiles.role IN ('admin', 'company_admin')
    )
  );

-- 1c. referrals: la empresa referente y la referida pueden leer
CREATE POLICY "referrals_super_admin_all" ON public.referrals
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin')
  );

CREATE POLICY "referrals_company_read" ON public.referrals
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND (
          profiles.company_id = referrals.referrer_company_id
          OR profiles.company_id = referrals.referred_company_id
        )
    )
  );

-- ─── 2. REVOCAR EXECUTE de funciones admin a roles públicos ─────────────────
-- Estas funciones son de uso exclusivo del sistema interno, NO deben ser
-- accesibles vía REST API por usuarios anónimos ni autenticados genéricos.

REVOKE EXECUTE ON FUNCTION public.admin_change_password(uuid, text)   FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_confirm_user_email(uuid)       FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_user(uuid)              FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.check_subscription_expirations()     FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()                    FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.set_user_role(uuid, text, uuid)      FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.is_subscription_field_unchanged(companies) FROM anon, authenticated;

-- Estas sí deben ser accesibles por authenticated (las usan las RLS policies internamente)
-- Pero revocamos de anon:
REVOKE EXECUTE ON FUNCTION public.get_my_company_id()                  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_role()                        FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_super_admin()                     FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin_of_company(uuid)            FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_agent_on_commission(uuid)         FROM anon;
REVOKE EXECUTE ON FUNCTION public.check_commission_access(uuid, uuid)  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_commission_company_id(uuid)      FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user()                    FROM anon, authenticated;

-- ─── 3. FIJAR search_path en funciones vulnerables ──────────────────────────
-- Previene ataques de "search path hijacking" en funciones SECURITY DEFINER

CREATE OR REPLACE FUNCTION public.get_my_company_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT company_id FROM profiles WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role FROM profiles WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_admin_of_company(comp_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND company_id = comp_id
      AND role IN ('admin', 'company_admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_agent_on_commission(comm_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM commission_agents ca
    JOIN profiles p ON p.id = ca.agent_id
    WHERE ca.commission_id = comm_id AND p.id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.get_commission_company_id(comm_id uuid)
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT company_id FROM property_commissions WHERE id = comm_id LIMIT 1;
$$;

-- ─── 4. GALERÍA: restringir write policy (era USING true / WITH CHECK true) ──
-- Solo company_admin/admin puede insertar/actualizar/borrar fotos de su empresa
DROP POLICY IF EXISTS gallery_auth_write ON public.gallery;

CREATE POLICY gallery_auth_write ON public.gallery
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN profiles prof ON prof.id = auth.uid()
      WHERE p.id = gallery.property_id
        AND p.company_id = prof.company_id
        AND prof.role IN ('admin', 'company_admin', 'agent', 'super_admin')
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN profiles prof ON prof.id = auth.uid()
      WHERE p.id = gallery.property_id
        AND p.company_id = prof.company_id
        AND prof.role IN ('admin', 'company_admin', 'agent', 'super_admin')
    )
  );

-- ─── 5. PROPERTY LIKES: acotar políticas de INSERT/DELETE ────────────────────
-- INSERT solo si el company_id del like coincide con el company_id de la propiedad
DROP POLICY IF EXISTS likes_insert_all ON public.property_likes;
DROP POLICY IF EXISTS likes_delete_all ON public.property_likes;

CREATE POLICY likes_insert_validated ON public.property_likes
  FOR INSERT WITH CHECK (
    -- El company_id del like debe corresponder a la empresa de la propiedad
    EXISTS (
      SELECT 1 FROM properties
      WHERE properties.id = property_likes.property_id
        AND properties.company_id = property_likes.company_id
    )
  );

CREATE POLICY likes_delete_own ON public.property_likes
  FOR DELETE USING (
    -- Solo se puede quitar el like del mismo visitor_id
    visitor_id = current_setting('request.headers', true)::jsonb->>'x-visitor-id'
    OR
    -- O si es admin de la empresa
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.company_id = property_likes.company_id
        AND profiles.role IN ('admin', 'company_admin', 'super_admin')
    )
  );

-- ─── 6. PROPERTY VIEWS: acotar INSERT para que valide empresa ────────────────
DROP POLICY IF EXISTS "Anyone can record a view" ON public.property_views;

CREATE POLICY "views_insert_validated" ON public.property_views
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM properties
      WHERE properties.id = property_views.property_id
        AND properties.company_id = property_views.company_id
    )
  );

-- ─── 7. VISITOR SESSIONS: acotar para requerir company_id válido ─────────────
DROP POLICY IF EXISTS "Allow public upserts for visitor_sessions" ON public.visitor_sessions;

CREATE POLICY "visitor_sessions_upsert_validated" ON public.visitor_sessions
  FOR ALL USING (true)
  WITH CHECK (
    -- El company_id debe existir en la tabla companies
    EXISTS (SELECT 1 FROM companies WHERE companies.id = visitor_sessions.company_id)
  );
;
