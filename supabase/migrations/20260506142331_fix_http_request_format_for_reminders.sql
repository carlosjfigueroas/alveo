CREATE OR REPLACE FUNCTION public.check_upcoming_expirations()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  company_record RECORD;
BEGIN
  FOR company_record IN 
    SELECT id 
    FROM companies 
    WHERE subscription_status = 'active' 
    AND subscription_ends_at::date = (CURRENT_DATE + interval '5 days')::date
  LOOP
    PERFORM
      public.http((
        'POST',
        'https://ummvqwhdidlhfybnjmzc.supabase.co/functions/v1/send-subscription-email',
        ARRAY[
          public.http_header('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbXZxd2hkaWRsaGZ5Ym5qbXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTkyMjksImV4cCI6MjA5MDAzNTIyOX0.iXh1kUXUkCTJkWSeKRKrQvghyKg7K-bpgzS3UAQZzX4'),
          public.http_header('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbXZxd2hkaWRsaGZ5Ym5qbXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTkyMjksImV4cCI6MjA5MDAzNTIyOX0.iXh1kUXUkCTJkWSeKRKrQvghyKg7K-bpgzS3UAQZzX4')
        ],
        'application/json',
        jsonb_build_object(
          'type', 'payment_reminder',
          'company_id', company_record.id
        )::text
      )::public.http_request);
  END LOOP;
END;
$function$;;
