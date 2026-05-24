-- Revertir acceso explícito a usuarios autenticados para inmuebles públicos.
-- Volver a la política original (que usaba el rol 'public' de Postgres).
DROP POLICY IF EXISTS "Public: can view public properties" ON properties;
CREATE POLICY "Public: can view public properties" ON properties
FOR SELECT TO public
USING (is_public = true);
;
