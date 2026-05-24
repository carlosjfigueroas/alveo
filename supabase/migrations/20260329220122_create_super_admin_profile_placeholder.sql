
-- Trigger para asignar automáticamente el perfil correcto cuando se crea un usuario en Auth
-- Esto se ejecutará cuando el Super Admin cree su cuenta
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'client'  -- rol por defecto; el Super Admin se asigna manualmente
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Asegurarse de que el trigger existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Función para que el Super Admin pueda elevar el rol de otro usuario
CREATE OR REPLACE FUNCTION public.set_user_role(target_user_id UUID, new_role TEXT, new_company_id UUID DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: only super_admin can change roles';
  END IF;
  
  UPDATE public.profiles
  SET role = new_role,
      company_id = new_company_id
  WHERE id = target_user_id;
END;
$$;
;
