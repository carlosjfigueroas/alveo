-- Asegurar que tanto usuarios anónimos como autenticados puedan ver inmuebles públicos de cualquier empresa.
DROP POLICY IF EXISTS "Public: can view public properties" ON properties;
CREATE POLICY "Public: can view public properties" ON properties
FOR SELECT TO anon, authenticated
USING (is_public = true);
;
