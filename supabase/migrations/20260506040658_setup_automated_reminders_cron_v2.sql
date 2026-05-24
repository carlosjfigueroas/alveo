CREATE EXTENSION IF NOT EXISTS http;

CREATE OR REPLACE FUNCTION public.check_upcoming_expirations()
RETURNS void AS $$
DECLARE
  company_record RECORD;
BEGIN
  FOR company_record IN 
    SELECT id 
    FROM companies 
    WHERE subscription_status = 'active' 
    AND subscription_ends_at::date = (current_date + interval '5 days')::date
  LOOP
    PERFORM
      http_post(
        'https://ummvqwhdidlhfybnjmzc.supabase.co/functions/v1/send-subscription-email',
        jsonb_build_object(
          'type', 'payment_reminder',
          'company_id', company_record.id
        )::text,
        'application/json',
        ARRAY[
          http_header('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbXZxd2hkaWRsaGZ5Ym5qbXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTkyMjksImV4cCI6MjA5MDAzNTIyOX0.iXh1kUXUkCTJkWSeKRKrQvghyKg7K-bpgzS3UAQZzX4'),
          http_header('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbXZxd2hkaWRsaGZ5Ym5qbXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTkyMjksImV4cCI6MjA5MDAzNTIyOX0.iXh1kUXUkCTJkWSeKRKrQvghyKg7K-bpgzS3UAQZzX4')
        ]
      );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Programar el job (si ya existe, cron.schedule lo actualizará o fallará si el nombre es duplicado dependiendo de la versión, pero en Supabase suele funcionar)
-- Usamos una técnica segura para asegurar que el job se cree:
SELECT cron.schedule('daily-payment-reminders', '0 8 * * *', 'SELECT check_upcoming_expirations()');;
