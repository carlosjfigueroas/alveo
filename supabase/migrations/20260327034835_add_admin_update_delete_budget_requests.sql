
-- Allow admins to UPDATE budget_requests
CREATE POLICY "Admins pueden actualizar solicitudes"
ON budget_requests
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- Allow admins to DELETE budget_requests
CREATE POLICY "Admins pueden eliminar solicitudes"
ON budget_requests
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);
;
