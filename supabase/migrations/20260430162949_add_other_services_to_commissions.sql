ALTER TABLE property_commissions DROP CONSTRAINT IF EXISTS property_commissions_operation_type_check;
ALTER TABLE property_commissions ADD CONSTRAINT property_commissions_operation_type_check 
CHECK (operation_type = ANY (ARRAY['Venta'::text, 'Alquiler'::text, 'Gestión de Alquileres'::text, 'Otros Servicios'::text]));;
