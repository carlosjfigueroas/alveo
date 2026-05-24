UPDATE app_settings 
SET value = '{"max_properties": 35, "max_photos_per_property": 10}'::jsonb 
WHERE key = 'default_limits' AND company_id IS NULL;
