-- 1. Columnas en companies
ALTER TABLE public.companies 
ADD COLUMN IF NOT EXISTS max_photos_per_property INT DEFAULT 10,
ADD COLUMN IF NOT EXISTS max_properties INT DEFAULT 20,
ADD COLUMN IF NOT EXISTS referral_bonus_photos INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS referral_bonus_properties INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS referred_by_salesperson TEXT,
ADD COLUMN IF NOT EXISTS acquisition_channel TEXT DEFAULT 'organic';

UPDATE public.companies SET max_photos_per_property = 10, max_properties = 20 WHERE max_photos_per_property IS NULL;

-- 2. Salespersons
CREATE TABLE IF NOT EXISTS public.salespersons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alias TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    commission_pct NUMERIC DEFAULT 20.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. App Settings (JSONB)
INSERT INTO public.app_settings (key, value, company_id)
VALUES ('active_referral_strategy', '"strategy_1"'::jsonb, NULL)
ON CONFLICT (key) DO UPDATE SET value = '"strategy_1"'::jsonb;

-- 4. Commissions
CREATE TABLE IF NOT EXISTS public.commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    salesperson_id UUID REFERENCES public.salespersons(id),
    company_id UUID REFERENCES public.companies(id),
    payment_id UUID, 
    amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending', 
    created_at TIMESTAMPTZ DEFAULT NOW(),
    paid_at TIMESTAMPTZ
);

-- 5. RLS
ALTER TABLE public.salespersons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super Admins can manage salespersons" ON public.salespersons;
DROP POLICY IF EXISTS "Super Admins can manage commissions" ON public.commissions;
DROP POLICY IF EXISTS "Anyone can read salespersons (for validation)" ON public.salespersons;

CREATE POLICY "Super Admins can manage salespersons" ON public.salespersons USING ( (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin' );
CREATE POLICY "Super Admins can manage commissions" ON public.commissions USING ( (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin' );
CREATE POLICY "Anyone can read salespersons (for validation)" ON public.salespersons FOR SELECT USING (true);
;
