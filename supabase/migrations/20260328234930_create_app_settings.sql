CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS pero permitir lectura a todos y escritura a autenticados (o admins)
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON app_settings FOR SELECT USING (true);
CREATE POLICY "Users can insert settings" ON app_settings FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update settings" ON app_settings FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Users can delete settings" ON app_settings FOR DELETE USING (auth.role() = 'authenticated');;
