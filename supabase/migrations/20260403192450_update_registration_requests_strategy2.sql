ALTER TABLE public.company_registration_requests 
ADD COLUMN IF NOT EXISTS acquisition_channel TEXT DEFAULT 'organic', 
ADD COLUMN IF NOT EXISTS referred_alias TEXT;
;
