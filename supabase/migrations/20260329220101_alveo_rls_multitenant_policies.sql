
-- ============================================================
-- ALVEO: Función helper para obtener el company_id del usuario autenticado
-- ============================================================
CREATE OR REPLACE FUNCTION get_my_company_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT company_id FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  )
$$;

-- ============================================================
-- PROPERTIES
-- Eliminar políticas existentes y crear las nuevas
-- ============================================================
DROP POLICY IF EXISTS "Allow public read" ON public.properties;
DROP POLICY IF EXISTS "Allow admin read" ON public.properties;
DROP POLICY IF EXISTS "Allow admin write" ON public.properties;
DROP POLICY IF EXISTS "properties_public_read" ON public.properties;
DROP POLICY IF EXISTS "properties_admin_read" ON public.properties;
DROP POLICY IF EXISTS "properties_admin_write" ON public.properties;

-- Visitantes anónimos: solo ver inmuebles públicos (su empresa filtra en el cliente)
CREATE POLICY "prop_anon_read" ON public.properties
  FOR SELECT TO anon
  USING (is_public = TRUE);

-- Usuarios autenticados de empresa: ver todos los de su empresa
CREATE POLICY "prop_company_read" ON public.properties
  FOR SELECT TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id());

-- Admins de empresa: escribir en su empresa
CREATE POLICY "prop_company_write" ON public.properties
  FOR ALL TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id())
  WITH CHECK (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- OWNERS
-- ============================================================
DROP POLICY IF EXISTS "Allow admin manage owners" ON public.owners;
DROP POLICY IF EXISTS "owners_admin_all" ON public.owners;

CREATE POLICY "owners_company_all" ON public.owners
  FOR ALL TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id())
  WITH CHECK (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- BUDGET_REQUESTS
-- ============================================================
DROP POLICY IF EXISTS "Allow anon insert" ON public.budget_requests;
DROP POLICY IF EXISTS "Allow admin read" ON public.budget_requests;
DROP POLICY IF EXISTS "budget_anon_insert" ON public.budget_requests;
DROP POLICY IF EXISTS "budget_admin_read" ON public.budget_requests;

-- Anónimos pueden insertar solicitudes (con su company_id)
CREATE POLICY "budget_anon_insert" ON public.budget_requests
  FOR INSERT TO anon
  WITH CHECK (true);

-- Autenticados ven las de su empresa
CREATE POLICY "budget_company_read" ON public.budget_requests
  FOR SELECT TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id());

CREATE POLICY "budget_company_update" ON public.budget_requests
  FOR UPDATE TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id());

CREATE POLICY "budget_company_delete" ON public.budget_requests
  FOR DELETE TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- APP_SETTINGS
-- ============================================================
DROP POLICY IF EXISTS "Allow all for admin" ON public.app_settings;
DROP POLICY IF EXISTS "app_settings_admin_all" ON public.app_settings;

CREATE POLICY "settings_public_read" ON public.app_settings
  FOR SELECT USING (true);

CREATE POLICY "settings_company_write" ON public.app_settings
  FOR ALL TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id())
  WITH CHECK (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- ABOUT_US
-- ============================================================
DROP POLICY IF EXISTS "about_us_public_read" ON public.about_us;
DROP POLICY IF EXISTS "about_us_admin_write" ON public.about_us;

CREATE POLICY "about_public_read" ON public.about_us
  FOR SELECT USING (true);

CREATE POLICY "about_company_write" ON public.about_us
  FOR ALL TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id())
  WITH CHECK (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- FAQS
-- ============================================================
DROP POLICY IF EXISTS "faqs_public_read" ON public.faqs;
DROP POLICY IF EXISTS "faqs_admin_write" ON public.faqs;

CREATE POLICY "faqs_public_read" ON public.faqs
  FOR SELECT USING (true);

CREATE POLICY "faqs_company_write" ON public.faqs
  FOR ALL TO authenticated
  USING (is_super_admin() OR company_id = get_my_company_id())
  WITH CHECK (is_super_admin() OR company_id = get_my_company_id());

-- ============================================================
-- GALLERY (hereda seguridad de properties via FK)
-- ============================================================
DROP POLICY IF EXISTS "gallery_public_read" ON public.gallery;
DROP POLICY IF EXISTS "gallery_admin_write" ON public.gallery;

CREATE POLICY "gallery_public_read" ON public.gallery
  FOR SELECT USING (true);

CREATE POLICY "gallery_auth_write" ON public.gallery
  FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- ============================================================
-- PROFILES: actualizar para incluir super_admin en lectura propia
-- ============================================================
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_update" ON public.profiles;

CREATE POLICY "profiles_own_read" ON public.profiles
  FOR SELECT USING (id = auth.uid() OR is_super_admin());

CREATE POLICY "profiles_own_update" ON public.profiles
  FOR UPDATE USING (id = auth.uid() OR is_super_admin());

CREATE POLICY "profiles_super_admin_insert" ON public.profiles
  FOR INSERT WITH CHECK (is_super_admin());
;
