-- Permite a los administradores de empresa crear perfiles (agentes) para su propia empresa
CREATE POLICY profiles_company_admin_insert ON public.profiles
  FOR INSERT
  WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'company_admin'
    AND company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND role = 'agent'
  );
;
