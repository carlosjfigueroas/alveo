-- Actualización de la función para cambiar contraseña (permite a Super Admin y a Company Admin sobre sus propios usuarios)
CREATE OR REPLACE FUNCTION public.admin_change_password(user_id uuid, new_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  caller_company_id uuid;
  target_company_id uuid;
BEGIN
  -- Obtener rol y empresa de quien llama
  SELECT role, company_id INTO caller_role, caller_company_id 
  FROM public.profiles WHERE id = auth.uid();

  -- Se requiere ser Admin de Empresa o Súper Admin
  IF caller_role NOT IN ('super_admin', 'company_admin') THEN
    RAISE EXCEPTION 'Acceso denegado.';
  END IF;

  -- Si es Admin de Empresa, verificar que el usuario objetivo pertenezca a la misma empresa
  IF caller_role = 'company_admin' THEN
    SELECT company_id INTO target_company_id FROM public.profiles WHERE id = user_id;
    IF caller_company_id IS NULL OR target_company_id IS NULL OR caller_company_id != target_company_id THEN
      RAISE EXCEPTION 'Acceso denegado: solo puedes modificar usuarios de tu propia empresa.';
    END IF;
  END IF;

  -- Cambiar password en tabla de auth
  UPDATE auth.users 
  SET 
    encrypted_password = crypt(new_password, gen_salt('bf')),
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
  WHERE id = user_id;

  -- Limpiar sesiones
  DELETE FROM auth.sessions WHERE auth.sessions.user_id = user_id;
END;
$$;

-- Actualización de la función para confirmar emails
CREATE OR REPLACE FUNCTION public.admin_confirm_user_email(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  caller_company_id uuid;
  user_company_id uuid;
BEGIN
  SELECT role, company_id INTO caller_role, caller_company_id 
  FROM public.profiles WHERE id = auth.uid();

  IF caller_role = 'super_admin' THEN
    UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = target_user_id;
  ELSIF caller_role = 'company_admin' THEN
    SELECT company_id INTO user_company_id FROM public.profiles WHERE id = target_user_id;
    IF caller_company_id = user_company_id THEN
      UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = target_user_id;
    ELSE
      RAISE EXCEPTION 'Acceso denegado.';
    END IF;
  ELSE
    RAISE EXCEPTION 'Acceso denegado.';
  END IF;
END;
$$;
;
