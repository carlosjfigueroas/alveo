ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'trial' CHECK (subscription_status IN ('trial','active','suspended','cancelled')),
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  ADD COLUMN IF NOT EXISTS subscription_starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS subscription_ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS billing_cycle TEXT DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly','annual')),
  ADD COLUMN IF NOT EXISTS base_price NUMERIC(10,2) DEFAULT 18.00,
  ADD COLUMN IF NOT EXISTS referral_discount NUMERIC(10,2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE DEFAULT gen_random_uuid()::text,
  ADD COLUMN IF NOT EXISTS referred_by_company_id UUID REFERENCES companies(id),
  ADD COLUMN IF NOT EXISTS referral_email_entered TEXT,
  ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'es' CHECK (language IN ('es','en')),
  ADD COLUMN IF NOT EXISTS contact_name TEXT,
  ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS grace_ends_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  billing_cycle TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','failed')),
  payment_method TEXT DEFAULT 'bank_transfer',
  reference TEXT,
  notes TEXT,
  confirmed_by TEXT,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_company_id UUID NOT NULL REFERENCES companies(id),
  referred_company_id UUID NOT NULL REFERENCES companies(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','active','cancelled')),
  activated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(referred_company_id)
);

CREATE TABLE IF NOT EXISTS company_registration_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  desired_domain TEXT,
  language TEXT DEFAULT 'es',
  billing_cycle TEXT DEFAULT 'monthly',
  referral_email TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);;
