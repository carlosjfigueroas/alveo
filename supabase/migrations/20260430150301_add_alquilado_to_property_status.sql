ALTER TABLE properties 
DROP CONSTRAINT IF EXISTS properties_status_check;

ALTER TABLE properties 
ADD CONSTRAINT properties_status_check 
CHECK (status = ANY (ARRAY['Disponible'::text, 'Reservado'::text, 'Vendido'::text, 'Alquilado'::text]));;
