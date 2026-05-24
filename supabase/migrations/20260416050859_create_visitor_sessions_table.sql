-- Create table for visitor sessions
CREATE TABLE IF NOT EXISTS public.visitor_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    visitor_id text NOT NULL,
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    first_seen_at timestamptz DEFAULT now() NOT NULL,
    last_seen_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE (visitor_id, company_id)
);

-- Enable RLS
ALTER TABLE public.visitor_sessions ENABLE ROW LEVEL SECURITY;

-- Policy to allow anonymous/public upserts
CREATE POLICY "Allow public upserts for visitor_sessions" ON public.visitor_sessions
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Create view for weekly unique visitors
CREATE OR REPLACE VIEW public.weekly_visitors AS
SELECT
    company_id,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM public.visitor_sessions
WHERE last_seen_at >= now() - interval '7 days'
GROUP BY company_id;
;
