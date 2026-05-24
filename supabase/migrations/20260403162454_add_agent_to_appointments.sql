ALTER TABLE budget_requests ADD COLUMN IF NOT EXISTS assigned_agent_id UUID REFERENCES profiles(id);;
