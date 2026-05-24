ALTER TABLE properties DROP CONSTRAINT IF EXISTS properties_type_check;
ALTER TABLE properties ADD CONSTRAINT properties_type_check 
CHECK (type = ANY (ARRAY[
  'Local'::text, 
  'Oficina'::text, 
  'Almacén'::text, 
  'Galpon'::text, 
  'Casa'::text, 
  'Apartamento'::text, 
  'Ático'::text, 
  'Dúplex'::text, 
  'Loft'::text, 
  'Estudio'::text, 
  'Terreno'::text, 
  'Inversión'::text, 
  'Tienda'::text, 
  'Hotel'::text, 
  'Restauración'::text, 
  'Industrial'::text, 
  'Agricultura y bosques'::text, 
  'Otro'::text
]));;
