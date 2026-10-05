-- Fase 1 · Biblioteca de ejercicios. La feature se implementa en la fase 2; aqui
-- solo la tabla y sus politicas, porque `ejercicios_planificados` dependera de ella.
-- Referencia: docs/sql-schema.md (seccion "Ejercicio (biblioteca)").

create type tipo_ejercicio as enum ('fuerza', 'cardio');
create type estado_ejercicio as enum ('activo', 'eliminado');

create table ejercicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  grupo_muscular text,
  equipamiento text,
  descripcion text not null,
  video_ejemplo_url text,
  tipo tipo_ejercicio not null,
  estado estado_ejercicio not null default 'activo',
  creado_en timestamptz not null default now()
);

create unique index ejercicios_nombre_activo_unico
  on ejercicios (lower(nombre))
  where estado = 'activo';

alter table ejercicios enable row level security;

-- Sin `delete`: la baja de un ejercicio es un update a estado = 'eliminado'.
grant select, insert, update on ejercicios to authenticated;

-- Los privilegios por defecto del esquema `public` de Supabase dejan TRUNCATE,
-- TRIGGER y REFERENCES a `anon` y `authenticated` incluso con la autoexposicion
-- desactivada. TRUNCATE no pasa por RLS, asi que se revoca explicitamente: la
-- regla "bajas siempre logicas" no debe depender de que PostgREST no exponga esa
-- operacion hoy. TRIGGER y REFERENCES tampoco los necesita ningun caso de uso.
revoke truncate, trigger, references on table ejercicios from anon, authenticated;

-- Todos los usuarios autenticados leen la biblioteca completa, tambien los
-- clientes (necesitan ver la descripcion y el video de ejemplo).
create policy "cualquier usuario autenticado lee la biblioteca"
  on ejercicios for select
  to authenticated
  using (true);

create policy "solo el entrenador anade a la biblioteca"
  on ejercicios for insert
  to authenticated
  with check (es_entrenador());

create policy "solo el entrenador edita la biblioteca"
  on ejercicios for update
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());
