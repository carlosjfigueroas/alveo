-- Add person_type to owners
ALTER TABLE owners ADD COLUMN IF NOT EXISTS person_type TEXT DEFAULT 'Persona Natural' CHECK (person_type IN ('Persona Natural', 'Persona Juridica', 'Ente Gubernamental'));

-- Add tax fields to companies
ALTER TABLE companies ADD COLUMN IF NOT EXISTS tax_label TEXT DEFAULT 'IVA';
ALTER TABLE companies ADD COLUMN IF NOT EXISTS tax_percentage NUMERIC DEFAULT 16.0;

-- Update profiles default commission
ALTER TABLE profiles ALTER COLUMN default_commission_pct SET DEFAULT 50.0;
UPDATE profiles SET default_commission_pct = 50.0 WHERE default_commission_pct = 0.0 OR default_commission_pct IS NULL;;
