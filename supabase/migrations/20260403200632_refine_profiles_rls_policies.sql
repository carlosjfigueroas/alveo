-- Drop existing restrictive policies
DROP POLICY IF EXISTS profiles_company_admin_insert ON public.profiles;
DROP POLICY IF EXISTS profiles_company_update ON public.profiles;

-- New Insert Policy for Company Admins / Admins
-- (Using auth.jwt() for role to avoid recursion if possible, but the app uses profiles for role too)
CREATE POLICY profiles_company_admin_insert ON public.profiles
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('company_admin', 'admin')
    AND p.company_id = public.profiles.company_id
  )
);

-- New Update Policy for Company Admins / Admins
CREATE POLICY profiles_company_admin_update ON public.profiles
FOR UPDATE
USING (
  is_super_admin() OR 
  auth.uid() = id OR 
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('company_admin', 'admin')
    AND p.company_id = public.profiles.company_id
  )
)
WITH CHECK (
  is_super_admin() OR 
  auth.uid() = id OR 
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('company_admin', 'admin')
    AND p.company_id = public.profiles.company_id
  )
);;
