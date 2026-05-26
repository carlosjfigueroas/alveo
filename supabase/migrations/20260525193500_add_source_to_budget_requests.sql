ALTER TABLE public.budget_requests ADD COLUMN source VARCHAR NOT NULL DEFAULT 'web';

-- Migrate existing data
UPDATE public.budget_requests 
SET source = 'ava' 
WHERE notes = 'Registrado automáticamente por la Asistente de IA Ava.' 
   OR client_email = 'no-email@local';

UPDATE public.budget_requests
SET source = 'manual'
WHERE client_email = 'agenda@local';
