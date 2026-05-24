
ALTER TABLE budget_requests
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS responded_at timestamptz;

-- Allow the status column to only have known values
ALTER TABLE budget_requests
  DROP CONSTRAINT IF EXISTS budget_requests_status_check;
ALTER TABLE budget_requests
  ADD CONSTRAINT budget_requests_status_check CHECK (status IN ('pending', 'responded', 'rejected'));
;
