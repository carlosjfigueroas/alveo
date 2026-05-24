ALTER TABLE commission_agents 
ADD CONSTRAINT commission_agents_commission_id_agent_id_key 
UNIQUE (commission_id, agent_id);;
