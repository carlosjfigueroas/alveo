
-- ============================================================
-- ALVEO MULTI-TENANT: Extender tabla profiles
-- ============================================================

-- Añadir company_id (nullable: super_admin no tiene empresa fija)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

-- Ampliar el CHECK de 'role' para incluir los nuevos roles de Alveo
-- Primero eliminamos el constraint existente
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Luego añadimos el nuevo con todos los valores válidos
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check CHECK (
    role = ANY (ARRAY[
      'admin'::text,       -- rol existente (company_admin equivalente)
      'agent'::text,       -- rol existente
      'client'::text,      -- rol existente
      'company_admin'::text,  -- nuevo: admin de empresa Alveo
      'super_admin'::text     -- nuevo: super administrador Alveo
    ])
  );
;
