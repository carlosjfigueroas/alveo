
-- Actualizamos la vista para que las que tienen 0 likes se ordenen por fecha de creación (novedad)
CREATE OR REPLACE VIEW top_liked_properties AS
  SELECT p.*, COALESCE(lc.likes_count, 0) AS likes_count
  FROM properties p
  LEFT JOIN property_likes_count lc ON p.id = lc.property_id
  WHERE p.is_public = true -- Solo públicas
  ORDER BY likes_count DESC, p.created_at DESC;
;
