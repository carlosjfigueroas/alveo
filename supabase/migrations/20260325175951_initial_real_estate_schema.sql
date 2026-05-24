-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabla de Perfiles (Extensión de auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'agent', 'client')) DEFAULT 'client',
    dark_mode BOOLEAN DEFAULT FALSE,
    language TEXT DEFAULT 'es',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Tabla de Propietarios
CREATE TABLE IF NOT EXISTS owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    phone TEXT,
    id_document TEXT,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Tabla de Inmuebles (Locales Comerciales)
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(15, 2),
    address TEXT,
    type TEXT CHECK (type IN ('Local', 'Oficina', 'Almacén', 'Otro')) DEFAULT 'Local',
    operation_type TEXT CHECK (operation_type IN ('Venta', 'Alquiler')) DEFAULT 'Alquiler',
    status TEXT CHECK (status IN ('Disponible', 'Reservado', 'Vendido')) DEFAULT 'Disponible',
    owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES profiles(id),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. Características de Inmuebles
CREATE TABLE IF NOT EXISTS property_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE UNIQUE,
    bathrooms INTEGER DEFAULT 0,
    area_m2 NUMERIC(10, 2) NOT NULL,
    parking_spaces INTEGER DEFAULT 0,
    has_air_con BOOLEAN DEFAULT FALSE,
    has_extra_storage BOOLEAN DEFAULT FALSE
);

-- 5. Galería de Imágenes
CREATE TABLE IF NOT EXISTS gallery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. Registro de Presupuestos
CREATE TABLE IF NOT EXISTS budget_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_email TEXT NOT NULL,
    client_name TEXT,
    property_list JSONB NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. Configuración de RLS (Row Level Security) para todas las tablas

-- Habilitar RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_requests ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PARA PROFILES
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Usuarios pueden ver su propio perfil') THEN
        CREATE POLICY "Usuarios pueden ver su propio perfil" ON profiles FOR SELECT USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins pueden ver todos los perfiles') THEN
        CREATE POLICY "Admins pueden ver todos los perfiles" ON profiles FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
    END IF;
END $$;

-- POLÍTICAS PARA PROPERTIES
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Lectura pública de inmuebles públicos') THEN
        CREATE POLICY "Lectura pública de inmuebles públicos" ON properties FOR SELECT USING (is_public = true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins gestionan inmuebles') THEN
        CREATE POLICY "Admins gestionan inmuebles" ON properties FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'agent')));
    END IF;
END $$;

-- POLÍTICAS PARA OWNERS
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Lectura pública de propietarios') THEN
        CREATE POLICY "Lectura pública de propietarios" ON owners FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins gestionan propietarios') THEN
        CREATE POLICY "Admins gestionan propietarios" ON owners FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
    END IF;
END $$;

-- POLÍTICAS PARA GALLERY Y DETAILS
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Lectura pública de detalles y galería') THEN
        CREATE POLICY "Lectura pública de detalles y galería" ON property_details FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Lectura pública de fotos') THEN
        CREATE POLICY "Lectura pública de fotos" ON gallery FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins gestionan detalles y fotos') THEN
        CREATE POLICY "Admins gestionan detalles y fotos" ON property_details FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins gestionan galería') THEN
        CREATE POLICY "Admins gestionan galería" ON gallery FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
    END IF;
END $$;

-- POLÍTICAS PARA BUDGET_REQUESTS
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Nadie lee presupuestos excepto admins') THEN
        CREATE POLICY "Nadie lee presupuestos excepto admins" ON budget_requests FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Cualquiera puede insertar solicitudes de presupuesto') THEN
        CREATE POLICY "Cualquiera puede insertar solicitudes de presupuesto" ON budget_requests FOR INSERT WITH CHECK (true);
    END IF;
END $$;
;
