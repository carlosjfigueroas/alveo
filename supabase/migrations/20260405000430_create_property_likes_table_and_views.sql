
-- 1. Table
CREATE TABLE IF NOT EXISTS property_likes (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  visitor_id  text NOT NULL,
  property_id uuid NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  company_id  uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now(),
  UNIQUE (visitor_id, property_id)
);

-- 2. Index
CREATE INDEX IF NOT EXISTS idx_property_likes_property ON property_likes(property_id);
CREATE INDEX IF NOT EXISTS idx_property_likes_company ON property_likes(company_id);

-- 3. RLS
ALTER TABLE property_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes_read_all" ON property_likes FOR SELECT USING (true);
CREATE POLICY "likes_insert_all" ON property_likes FOR INSERT WITH CHECK (true);
CREATE POLICY "likes_delete_all" ON property_likes FOR DELETE USING (true);

-- 4. Views
CREATE OR REPLACE VIEW property_likes_count AS
  SELECT property_id, COUNT(*) AS likes_count
  FROM property_likes
  GROUP BY property_id;

CREATE OR REPLACE VIEW top_liked_properties AS
  SELECT p.*, COALESCE(lc.likes_count, 0) AS likes_count
  FROM properties p
  LEFT JOIN property_likes_count lc ON p.id = lc.property_id
  ORDER BY likes_count DESC;
;
