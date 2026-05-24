
CREATE TABLE public.carousel_actions (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id  TEXT NOT NULL,
  slot        INTEGER NOT NULL CHECK (slot BETWEEN 1 AND 10),
  action      TEXT,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (company_id, slot)
);

ALTER TABLE public.carousel_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read carousel_actions"
  ON public.carousel_actions FOR SELECT USING (true);

CREATE POLICY "Authenticated write carousel_actions"
  ON public.carousel_actions FOR ALL
  USING (auth.role() = 'authenticated');
;
