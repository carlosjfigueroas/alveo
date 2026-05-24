ALTER TABLE public.payments 
DROP CONSTRAINT payments_status_check;

ALTER TABLE public.payments 
ADD CONSTRAINT payments_status_check 
CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'failed'::text, 'rejected'::text]));
;
