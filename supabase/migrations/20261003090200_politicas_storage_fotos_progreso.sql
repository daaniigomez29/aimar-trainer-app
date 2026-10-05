-- Fase 5 (3/4) · Politicas del bucket `fotos-progreso`.
--
-- El bucket en si no se crea aqui: lo declara `supabase/config.toml` para local y
-- hay que crearlo en el panel (o con `supabase config push`) para dev y
-- produccion. Lo que si vive en el repositorio son sus politicas, porque son RLS
-- normal sobre `storage.objects`, igual que las del resto del esquema.
--
-- CONVENCION DE RUTA: `<cliente_id>/<registro_medidas_id>/<archivo>`. El primer
-- segmento es el dueno, y es lo que miran las politicas: asi el permiso se resuelve
-- sin consultar `fotos_progreso`, que es lo que haria falta si la ruta no llevara
-- el cliente delante. `storage.foldername(name)` devuelve los segmentos de carpeta
-- del objeto, de modo que `[1]` es ese `<cliente_id>`.
--
-- El bucket es privado: estas politicas gobiernan tanto la subida como la firma de
-- la URL con la que se muestra la foto. Sin politica no hay acceso, que es
-- justamente lo que deja fuera al administrador.

-- El cliente sube, consulta, reemplaza y borra lo que cuelga de su propia carpeta.
create policy "el cliente gestiona sus fotos de progreso"
  on storage.objects for all
  to authenticated
  using (
    bucket_id = 'fotos-progreso'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'fotos-progreso'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- El entrenador solo lee. No sube ni borra fotos de un cliente: la foto es del
-- cliente, el entrenador la consulta.
create policy "el entrenador consulta las fotos de progreso"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'fotos-progreso' and es_entrenador());
