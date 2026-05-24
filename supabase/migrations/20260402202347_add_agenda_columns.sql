ALTER TABLE budget_requests
  ADD COLUMN is_appointment BOOLEAN DEFAULT FALSE,
  ADD COLUMN appointment_date DATE,
  ADD COLUMN appointment_time TIME WITHOUT TIME ZONE,
  ADD COLUMN appointment_status TEXT DEFAULT 'pending';;
