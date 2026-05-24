ALTER TABLE public.property_commissions
ADD COLUMN IF NOT EXISTS final_price numeric DEFAULT 0;

UPDATE public.property_commissions pc
SET final_price = ph.final_price
FROM public.property_history ph
WHERE pc.history_id = ph.id;;
