-- Fase 1 · Ficha de cliente. Baja siempre logica (estado = 'baja'), nunca DELETE.
-- Referencia: docs/sql-schema.md (seccion "Cliente").

create type estado_cliente as enum ('activo', 'baja');
create type dia_semana as enum (
  'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'
);

create table clientes (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  correo text not null,
  fecha_nacimiento date,
  altura_cm numeric(5, 2),
  peso_inicial_kg numeric(5, 2),
  objetivos text,
  dia_control_preferido dia_semana not null default 'domingo',
  estado estado_cliente not null default 'activo',
  fecha_alta timestamptz not null default now(),
  fecha_baja timestamptz,

  constraint correo_formato check (correo ~* '^[^@]+@[^@]+\.[^@]+$'),
  constraint baja_coherente check (
    (estado = 'activo' and fecha_baja is null) or
    (estado = 'baja' and fecha_baja is not null and fecha_baja > fecha_alta)
  )
);

-- La unicidad de correo solo aplica entre clientes activos: un correo dado de
-- baja puede reutilizarse.
create unique index clientes_correo_activo_unico
  on clientes (lower(correo))
  where estado = 'activo';

alter table clientes enable row level security;

-- Sin `delete`: la baja de un cliente es siempre logica (update a estado =
-- 'baja'). Al no concederse el privilegio, no hay borrado fisico posible desde
-- la API ni para el entrenador, aunque su politica sea `for all`.
grant select, insert, update on clientes to authenticated;

-- `service_role` salta RLS (tiene BYPASSRLS), pero NO los privilegios de tabla de
-- Postgres: sin este GRANT, una Edge Function recibe "permission denied for table".
-- No se le concede `delete`: las Edge Functions solo necesitan deshacer un alta a
-- medias, y eso lo resuelve `auth.admin.deleteUser`, que cascadea por la FK a
-- auth.users. Asi el borrado fisico sigue siendo imposible desde la API.
grant select, insert, update on clientes to service_role;

-- Los privilegios por defecto del esquema `public` de Supabase dejan TRUNCATE,
-- TRIGGER y REFERENCES a `anon` y `authenticated` incluso con la autoexposicion
-- desactivada. TRUNCATE no pasa por RLS, asi que se revoca explicitamente: la
-- regla "bajas siempre logicas" no debe depender de que PostgREST no exponga esa
-- operacion hoy. TRIGGER y REFERENCES tampoco los necesita ningun caso de uso.
revoke truncate, trigger, references on table clientes from anon, authenticated;

create policy "el cliente ve su propia ficha"
  on clientes for select
  to authenticated
  using (id = auth.uid());

create policy "el entrenador ve y gestiona todas las fichas"
  on clientes for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

create policy "el cliente edita datos limitados de su ficha"
  on clientes for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and estado = 'activo');
