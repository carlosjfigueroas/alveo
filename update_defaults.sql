ALTER TABLE companies ALTER COLUMN max_properties DROP DEFAULT;
ALTER TABLE companies ALTER COLUMN max_photos_per_property DROP DEFAULT;

INSERT INTO app_settings (key, company_id, value) 
VALUES ('default_limits', NULL, '{"max_properties": 20, "max_photos_per_property": 10}'::jsonb) 
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
