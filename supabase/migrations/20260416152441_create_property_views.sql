
-- 1. Table
CREATE TABLE IF NOT EXISTS property_views (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
  visitor_id  text NOT NULL,
  company_id  uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  viewed_at   timestamptz DEFAULT now()
);

-- 2. One row per visitor per property (lifetime dedup at DB level)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_property_view
  ON property_views(property_id, visitor_id);

-- 3. Aggregate view: count per property
CREATE OR REPLACE VIEW property_views_count AS
  SELECT property_id, COUNT(*) AS views_count
  FROM property_views
  GROUP BY property_id;

-- 4. Top viewed properties view (mirrors top_liked_properties pattern)
CREATE OR REPLACE VIEW top_viewed_properties AS
  SELECT p.*, pvc.views_count
  FROM properties p
  JOIN property_views_count pvc ON p.id = pvc.property_id
  ORDER BY pvc.views_count DESC;

-- 5. RLS: allow anyone to insert (public visitors)
ALTER TABLE property_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can record a view"
  ON property_views FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can read view counts"
  ON property_views FOR SELECT
  USING (true);
;
