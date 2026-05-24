
CREATE TABLE IF NOT EXISTS country_pricing (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  country        text NOT NULL UNIQUE,
  monthly_price  decimal(8,2) NOT NULL CHECK (monthly_price >= 5),
  referral_floor decimal(8,2) NOT NULL CHECK (referral_floor >= 5),
  is_active      boolean DEFAULT true,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER country_pricing_updated_at
  BEFORE UPDATE ON country_pricing
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE country_pricing ENABLE ROW LEVEL SECURITY;

-- Anyone can read (needed for /register to fetch prices without auth)
CREATE POLICY "country_pricing_read_all"
  ON country_pricing FOR SELECT
  USING (true);

-- Only superadmin service_role can write (mutations via service role key)
CREATE POLICY "country_pricing_write_superadmin"
  ON country_pricing FOR ALL
  USING (auth.role() = 'service_role');
;
