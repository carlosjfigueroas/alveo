ALTER TABLE companies ADD COLUMN IF NOT EXISTS linkedin_url TEXT;

NOTIFY pgrst, 'reload schema';
