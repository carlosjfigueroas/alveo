-- Add city to companies
ALTER TABLE public.companies ADD COLUMN city TEXT;

-- Add city to registration requests
ALTER TABLE public.company_registration_requests ADD COLUMN city TEXT;

-- Add bank_info to country_pricing
ALTER TABLE public.country_pricing ADD COLUMN bank_info TEXT;
;
