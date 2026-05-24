ALTER TABLE public.property_details 
ADD COLUMN IF NOT EXISTS pets_allowed BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS children_allowed BOOLEAN DEFAULT true;;
