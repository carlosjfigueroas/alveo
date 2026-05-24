DROP POLICY IF EXISTS "country_pricing_write_superadmin" ON country_pricing;

CREATE POLICY "country_pricing_write_superadmin" ON country_pricing
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
  )
);;
