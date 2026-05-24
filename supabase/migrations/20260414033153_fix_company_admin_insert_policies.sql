-- Fix gallery table policy to include company_admin
DROP POLICY IF EXISTS "Admins gestionan galería" ON public.gallery;
CREATE POLICY "Admins gestionan galería" ON public.gallery
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND (profiles.role = 'admin' OR profiles.role = 'company_admin')
  )
);

-- Fix storage policies to include company_admin for the property-images bucket
DROP POLICY IF EXISTS "Admin Insert Access" ON storage.objects;
CREATE POLICY "Admin Insert Access" ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  (bucket_id = 'property-images'::text) AND 
  ((SELECT profiles.role FROM public.profiles WHERE profiles.id = auth.uid()) = ANY (ARRAY['admin'::text, 'agent'::text, 'super_admin'::text, 'company_admin'::text]))
);

DROP POLICY IF EXISTS "Admin Update Access" ON storage.objects;
CREATE POLICY "Admin Update Access" ON storage.objects
FOR UPDATE
TO public
USING (
  (bucket_id = 'property-images'::text) AND 
  ((SELECT profiles.role FROM public.profiles WHERE profiles.id = auth.uid()) = ANY (ARRAY['admin'::text, 'agent'::text, 'super_admin'::text, 'company_admin'::text]))
);

DROP POLICY IF EXISTS "Admin Delete Access" ON storage.objects;
CREATE POLICY "Admin Delete Access" ON storage.objects
FOR DELETE
TO public
USING (
  (bucket_id = 'property-images'::text) AND 
  ((SELECT profiles.role FROM public.profiles WHERE profiles.id = auth.uid()) = ANY (ARRAY['admin'::text, 'agent'::text, 'super_admin'::text, 'company_admin'::text]))
);
;
