-- Table for About Us content and general settings
CREATE TABLE IF NOT EXISTS public.about_us (
    key text PRIMARY KEY,
    value_es text NOT NULL,
    value_en text NOT NULL,
    updated_at timestamptz DEFAULT now()
);

-- Table for Frequently Asked Questions
CREATE TABLE IF NOT EXISTS public.faqs (
    id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    question_es text NOT NULL,
    answer_es text NOT NULL,
    question_en text NOT NULL,
    answer_en text NOT NULL,
    sort_order int DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.about_us ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Allow public read about_us" ON public.about_us FOR SELECT USING (true);
CREATE POLICY "Allow public read faqs" ON public.faqs FOR SELECT USING (true);

-- Admin write access (assuming 'admin' role in profiles)
CREATE POLICY "Allow admin manage about_us" ON public.about_us
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Allow admin manage faqs" ON public.faqs
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
;
