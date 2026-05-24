CREATE OR REPLACE FUNCTION admin_delete_user(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verificar que quien llama es super_admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Solo los Súper Administradores pueden borrar usuarios.';
  END IF;

  -- Borrar de auth.users (la cascada borrará el perfil)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;;
