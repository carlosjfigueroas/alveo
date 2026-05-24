
DO $$
DECLARE
  demo_id UUID;
  owner1_id UUID;
  owner2_id UUID;
  owner3_id UUID;
  prop2_id UUID;
  prop3_id UUID;
BEGIN
  SELECT id INTO demo_id FROM public.companies WHERE is_demo = TRUE LIMIT 1;
  IF demo_id IS NULL THEN RAISE NOTICE 'No demo company'; RETURN; END IF;

  -- Dueños
  INSERT INTO public.owners (full_name, phone, company_id) VALUES ('Carlos Mendoza', '+34 612 345 678', demo_id) ON CONFLICT DO NOTHING;
  INSERT INTO public.owners (full_name, phone, company_id) VALUES ('María García', '+34 698 765 432', demo_id) ON CONFLICT DO NOTHING;
  INSERT INTO public.owners (full_name, phone, company_id) VALUES ('Grupo Inversiones SL', '+34 934 567 890', demo_id) ON CONFLICT DO NOTHING;
  SELECT id INTO owner1_id FROM public.owners WHERE full_name = 'Carlos Mendoza' AND company_id = demo_id LIMIT 1;
  SELECT id INTO owner2_id FROM public.owners WHERE full_name = 'María García' AND company_id = demo_id LIMIT 1;
  SELECT id INTO owner3_id FROM public.owners WHERE full_name = 'Grupo Inversiones SL' AND company_id = demo_id LIMIT 1;

  -- Inmueble 1: Local
  INSERT INTO public.properties (title, description, type, operation_type, status, price, address, country, state, city, is_public, company_id, owner_id)
  VALUES ('Local Comercial Centro Premium', 'Espléndido local comercial en pleno centro. Ideal para tienda, restaurante u oficina boutique. Amplio escaparate y excelente visibilidad.', 'Local', 'Alquiler', 'Disponible', 3500, 'Calle Gran Vía 45, Planta Baja', 'España', 'Madrid', 'Madrid', TRUE, demo_id, owner1_id) ON CONFLICT DO NOTHING;
  SELECT id INTO prop2_id FROM public.properties WHERE title = 'Local Comercial Centro Premium' AND company_id = demo_id LIMIT 1;
  IF prop2_id IS NOT NULL THEN INSERT INTO public.property_details (property_id, area_m2, bathrooms, has_air_con, has_security) VALUES (prop2_id, 120, 1, TRUE, TRUE) ON CONFLICT (property_id) DO NOTHING; END IF;

  -- Inmueble 2: Oficina
  INSERT INTO public.properties (title, description, type, operation_type, status, price, address, country, state, city, is_public, company_id, owner_id)
  VALUES ('Oficina Moderna Zona Empresarial', 'Oficina diáfana en el distrito empresarial. Open-space reformada con salas de reuniones y terraza privada.', 'Oficina', 'Alquiler', 'Disponible', 5200, 'Av. Parque Tecnológico 12, 3F', 'España', 'Cataluña', 'Barcelona', TRUE, demo_id, owner2_id) ON CONFLICT DO NOTHING;
  SELECT id INTO prop2_id FROM public.properties WHERE title = 'Oficina Moderna Zona Empresarial' AND company_id = demo_id LIMIT 1;
  IF prop2_id IS NOT NULL THEN INSERT INTO public.property_details (property_id, area_m2, bathrooms, parking_spaces, has_air_con, has_terrace, has_elevator, has_security) VALUES (prop2_id, 280, 2, 4, TRUE, TRUE, TRUE, TRUE) ON CONFLICT (property_id) DO NOTHING; END IF;

  -- Inmueble 3: Apartamento lujo
  INSERT INTO public.properties (title, description, type, operation_type, status, price, address, country, state, city, is_public, company_id, owner_id)
  VALUES ('Apartamento Vista al Mar 1ª Linea', 'Apartamento de lujo en primera línea de playa. Amueblado con diseño, cocina equipada y terraza con jacuzzi.', 'Apartamento', 'Venta', 'Disponible', 485000, 'Paseo Marítimo 8, Atico B', 'España', 'Andalucía', 'Málaga', TRUE, demo_id, owner3_id) ON CONFLICT DO NOTHING;
  SELECT id INTO prop3_id FROM public.properties WHERE title = 'Apartamento Vista al Mar 1ª Linea' AND company_id = demo_id LIMIT 1;
  IF prop3_id IS NOT NULL THEN INSERT INTO public.property_details (property_id, area_m2, bathrooms, bedrooms, parking_spaces, has_pool, has_air_con, is_waterfront, has_sea_view, is_furnished, has_terrace, has_balcony) VALUES (prop3_id, 95, 2, 3, 1, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE) ON CONFLICT (property_id) DO NOTHING; END IF;

  -- Inmueble 4: Almacén
  INSERT INTO public.properties (title, description, type, operation_type, status, price, address, country, state, city, is_public, company_id, owner_id)
  VALUES ('Almacen Industrial Poligono Norte', 'Nave industrial 850m². Altura libre 8m, muelles de carga, suelo reforzado. Acceso autopista.', 'Almacén', 'Alquiler', 'Disponible', 4800, 'Poligono Industrial Norte, Nave 7', 'España', 'Aragón', 'Zaragoza', TRUE, demo_id, owner1_id) ON CONFLICT DO NOTHING;
  SELECT id INTO prop2_id FROM public.properties WHERE title = 'Almacen Industrial Poligono Norte' AND company_id = demo_id LIMIT 1;
  IF prop2_id IS NOT NULL THEN INSERT INTO public.property_details (property_id, area_m2, bathrooms, parking_spaces, has_security) VALUES (prop2_id, 850, 2, 10, TRUE) ON CONFLICT (property_id) DO NOTHING; END IF;

  -- Inmueble 5: Villa
  INSERT INTO public.properties (title, description, type, operation_type, status, price, address, country, state, city, is_public, company_id, owner_id)
  VALUES ('Villa Mediterranea con Piscina', 'Villa en urbanizacion privada. Jardines, piscina climatizada, barbacoa. 5 habitaciones.', 'Casa', 'Venta', 'Reservado', 780000, 'Urb. Los Pinos, Calle Jacaranda 12', 'España', 'Valencia', 'Valencia', TRUE, demo_id, owner2_id) ON CONFLICT DO NOTHING;
  SELECT id INTO prop2_id FROM public.properties WHERE title = 'Villa Mediterranea con Piscina' AND company_id = demo_id LIMIT 1;
  IF prop2_id IS NOT NULL THEN INSERT INTO public.property_details (property_id, area_m2, bathrooms, bedrooms, parking_spaces, has_pool, has_garden, has_air_con, has_garage, plot_area_m2, year_built) VALUES (prop2_id, 320, 4, 5, 2, TRUE, TRUE, TRUE, TRUE, 680, 2019) ON CONFLICT (property_id) DO NOTHING; END IF;

  -- Solicitudes (property_list es jsonb)
  IF prop3_id IS NOT NULL THEN
    INSERT INTO public.budget_requests (client_name, client_email, phone, property_list, notes, status, company_id)
    VALUES ('Ana Lopez', 'ana.lopez@empresa.com', '+34 611 222 333', to_jsonb(ARRAY[prop3_id::text]), 'Nos interesa. Duracion minima del contrato?', 'pending', demo_id) ON CONFLICT DO NOTHING;
    INSERT INTO public.budget_requests (client_name, client_email, phone, property_list, notes, status, company_id)
    VALUES ('TechVentures SL', 'hola@techventures.es', '+34 931 999 888', to_jsonb(ARRAY[prop3_id::text]), 'Startup buscando oficina para Q1.', 'responded', demo_id) ON CONFLICT DO NOTHING;
    INSERT INTO public.budget_requests (client_name, client_email, phone, property_list, notes, status, company_id)
    VALUES ('Jean-Pierre Dubois', 'jp@gmail.com', '+33 6 12 34 56 78', to_jsonb(ARRAY[prop3_id::text]), 'Looking for a holiday home.', 'rejected', demo_id) ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE 'Demo seed v4 OK for %', demo_id;
END $$;
;
