-- Add more detail columns to support advanced filtering
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS year_built int;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS plot_area_m2 float8;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_pool boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_terrace boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_balcony boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_patio boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_garage boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_elevator boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_security boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS is_waterfront boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_sea_view boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_basement boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_fitted_kitchen boolean DEFAULT false;
ALTER TABLE property_details ADD COLUMN IF NOT EXISTS has_tennis_court boolean DEFAULT false;
;
