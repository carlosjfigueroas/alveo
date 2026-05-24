
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS ref_number SERIAL;
SELECT id, ref_number FROM public.properties LIMIT 5;
;
