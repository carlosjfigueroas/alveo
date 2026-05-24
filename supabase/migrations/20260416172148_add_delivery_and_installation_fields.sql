-- New delivery status and installation fields for property_details
ALTER TABLE property_details
  ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS has_electricity BOOLEAN DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS has_water_connections BOOLEAN DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS has_restroom_access BOOLEAN DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS has_ac_connection BOOLEAN DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS floor_level TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS has_storage_office_area BOOLEAN DEFAULT NULL;

-- Add a comment to document valid values
COMMENT ON COLUMN property_details.delivery_status IS 'Valid values: obra_gris, semi_acabado, listo_para_ocupar';
COMMENT ON COLUMN property_details.floor_level IS 'Valid values: incluido_en_direccion, planta_baja, mezzanina, primer_piso, segundo_piso, tercer_piso, cuarto_piso';;
