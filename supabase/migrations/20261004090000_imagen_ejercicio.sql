-- Imagen ilustrativa del ejercicio (entidad 5, atributo nuevo).
--
-- Una foto o ilustracion que muestre como se ejecuta el ejercicio, al lado de la
-- descripcion escrita. La ve el cliente cuando consulta la biblioteca.
--
-- POR QUE UN BUCKET PUBLICO, al contrario que `fotos-progreso`: esto no es un
-- dato personal de nadie. Es material de la biblioteca, igual para todos los
-- clientes, y se pinta en una lista: con un bucket privado habria que firmar una
-- URL por cada ejercicio cada vez que se abre la pantalla, y ninguna de esas URL
-- se podria cachear. Lo que si esta restringido es **escribir**: solo el
-- entrenador sube, reemplaza o borra.
--
-- La columna guarda la ruta dentro del bucket, no la URL completa: la URL se
-- construye con el dominio del proyecto, que cambia entre local y la nube.

alter table ejercicios add column imagen_ruta text;

alter table ejercicios add constraint imagen_ruta_no_vacia
  check (imagen_ruta is null or length(trim(imagen_ruta)) > 0);

-- ---------------------------------------------------------------------------
-- Politicas del bucket `imagenes-ejercicios`
-- ---------------------------------------------------------------------------
--
-- El bucket se declara en `supabase/config.toml` para local y hay que crearlo en
-- la nube, igual que `fotos-progreso`. Al ser publico, la lectura va por el
-- endpoint publico de Storage y no pasa por estas politicas; aqui solo se
-- gobierna quien escribe.

create policy "solo el entrenador sube imagenes de ejercicios"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'imagenes-ejercicios' and es_entrenador());

create policy "solo el entrenador reemplaza imagenes de ejercicios"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'imagenes-ejercicios' and es_entrenador())
  with check (bucket_id = 'imagenes-ejercicios' and es_entrenador());

-- Reemplazar la imagen de un ejercicio deja huerfana la anterior: hace falta
-- poder tirarla.
create policy "solo el entrenador borra imagenes de ejercicios"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'imagenes-ejercicios' and es_entrenador());

-- Lectura explicita para quien use la API en lugar del endpoint publico (por
-- ejemplo, al listar el contenido del bucket desde el panel).
create policy "cualquier usuario autenticado ve las imagenes de ejercicios"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'imagenes-ejercicios');
