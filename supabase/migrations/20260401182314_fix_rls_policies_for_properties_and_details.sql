-- Cleanup old policies to avoid confusion
DROP POLICY IF EXISTS "Lectura pública de inmuebles públicos" ON properties;
DROP POLICY IF EXISTS "Admins gestionan inmuebles" ON properties;
DROP POLICY IF EXISTS "prop_anon_read" ON properties;
DROP POLICY IF EXISTS "prop_company_read" ON properties;
DROP POLICY IF EXISTS "prop_company_write" ON properties;

DROP POLICY IF EXISTS "Lectura pública de detalles y galería" ON property_details;
DROP POLICY IF EXISTS "Admins gestionan detalles y fotos" ON property_details;

-- 1. Table: properties
-- PUBLIC access: can read public properties
CREATE POLICY "Public: can view public properties" ON properties
FOR SELECT TO anon, public
USING (is_public = true);

-- AUTH access: read/write based on company_id
CREATE POLICY "Auth: managed by company or super_admin" ON properties
FOR ALL TO authenticated
USING (
    is_super_admin() 
    OR company_id = get_my_company_id()
)
WITH CHECK (
    is_super_admin() 
    OR company_id = get_my_company_id()
);

-- 2. Table: property_details
-- Public access: read details of public properties
-- Actually, read all if public can see parent property. 
CREATE POLICY "Public: can view all via true" ON property_details
FOR SELECT TO anon, public
USING (true);

-- Auth access: Manage details if you own the company or are super_admin
-- We determine property ownership via the parent properties record
CREATE POLICY "Auth: managed by parent property owner" ON property_details
FOR ALL TO authenticated
USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM properties p
        WHERE p.id = property_details.property_id
        AND p.company_id = get_my_company_id()
    )
)
WITH CHECK (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM properties p
        WHERE p.id = property_details.property_id
        AND p.company_id = get_my_company_id()
    )
);

-- 3. Also check gallery while we're at it
DROP POLICY IF EXISTS "público ve galería" ON gallery;
DROP POLICY IF EXISTS "admins gestionan galería" ON gallery;

CREATE POLICY "Public: can view gallery" ON gallery
FOR SELECT TO anon, public
USING (true);

CREATE POLICY "Auth: manage gallery via parent ownership" ON gallery
FOR ALL TO authenticated
USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM properties p
        WHERE p.id = gallery.property_id
        AND p.company_id = get_my_company_id()
    )
)
WITH CHECK (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM properties p
        WHERE p.id = gallery.property_id
        AND p.company_id = get_my_company_id()
    )
);
;
