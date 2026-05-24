-- Function to initialize company content from a template
CREATE OR REPLACE FUNCTION public.initialize_new_company_content()
RETURNS TRIGGER AS $$
DECLARE
    template_company_id UUID;
BEGIN
    -- Get a template company (the demo)
    SELECT id INTO template_company_id FROM public.companies WHERE is_demo = true LIMIT 1;
    
    -- If no demo company, get the first available one to avoid empty content
    IF template_company_id IS NULL THEN
        SELECT id INTO template_company_id FROM public.companies LIMIT 1;
    END IF;

    -- If we have a template company and it's not the new one itself
    IF template_company_id IS NOT NULL AND template_company_id != NEW.id THEN
        -- Copy About Us content and replace 'NOMBRE EMPRESA' with the actual company name
        INSERT INTO public.about_us (key, value_es, value_en, company_id)
        SELECT 
            key, 
            REPLACE(value_es, 'NOMBRE EMPRESA', NEW.name),
            REPLACE(value_en, 'NOMBRE EMPRESA', NEW.name),
            NEW.id
        FROM public.about_us
        WHERE company_id = template_company_id
        ON CONFLICT (key, company_id) DO NOTHING;

        -- Copy FAQs and replace 'NOMBRE EMPRESA' with the actual company name
        INSERT INTO public.faqs (question_es, answer_es, question_en, answer_en, sort_order, company_id)
        SELECT 
            REPLACE(question_es, 'NOMBRE EMPRESA', NEW.name),
            REPLACE(answer_es, 'NOMBRE EMPRESA', NEW.name),
            REPLACE(question_en, 'NOMBRE EMPRESA', NEW.name),
            REPLACE(answer_en, 'NOMBRE EMPRESA', NEW.name),
            sort_order,
            NEW.id
        FROM public.faqs
        WHERE company_id = template_company_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run after a new company is created
DROP TRIGGER IF EXISTS on_company_created ON public.companies;
CREATE TRIGGER on_company_created
AFTER INSERT ON public.companies
FOR EACH ROW EXECUTE FUNCTION public.initialize_new_company_content();
;
