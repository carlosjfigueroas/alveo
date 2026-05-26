-- Migration to create the ai_usage table for tracking Ava's usage

CREATE TABLE IF NOT EXISTS public.ai_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  visitor_id TEXT,                    -- For anonymous visitors
  input_type TEXT DEFAULT 'text',     -- 'text' or 'voice'
  input_tokens INT DEFAULT 0,
  output_tokens INT DEFAULT 0,
  model TEXT DEFAULT 'gemini-2.0-flash',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

-- Each user sees their own usage
CREATE POLICY "users_see_own_usage" ON public.ai_usage
  FOR SELECT USING (auth.uid() = user_id);

-- Admins see all usage for their company
CREATE POLICY "admins_see_company_usage" ON public.ai_usage
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'company_admin')
    )
  );

-- Super Admins see everything
CREATE POLICY "super_admins_see_all_usage" ON public.ai_usage
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Edge Function inserts using service_role, no insert policy needed for anon/authenticated
-- But let's add one just in case the edge function uses authenticated client in the future
CREATE POLICY "service_insert_usage" ON public.ai_usage
  FOR INSERT WITH CHECK (true);
