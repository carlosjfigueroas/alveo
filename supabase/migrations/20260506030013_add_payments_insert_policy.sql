CREATE POLICY "payments_company_insert" ON "public"."payments"
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.company_id = payments.company_id
  )
);;
