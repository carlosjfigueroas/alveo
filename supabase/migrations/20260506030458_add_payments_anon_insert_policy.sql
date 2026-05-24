CREATE POLICY "payments_anon_insert" ON "public"."payments"
FOR INSERT
TO public
WITH CHECK (
  status = 'pending'
);;
