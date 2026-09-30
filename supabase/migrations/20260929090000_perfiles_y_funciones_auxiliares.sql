-- Fase 1 · Base de roles: tabla `perfiles` enlazada a auth.users y funciones
-- auxiliares usadas por las politicas RLS del resto del esquema.
-- Referencia: docs/sql-schema.md (seccion "Base: perfiles y funciones auxiliares").

create type rol_usuario as enum ('administrador', 'entrenador', 'cliente');

create table perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  rol rol_usuario not null,
  creado_en timestamptz not null default now()
);

alter table perfiles enable row level security;

-- Obligatorio con "Automatically expose new tables" desactivada: sin el GRANT,
-- PostgREST deniega la tabla antes de llegar a evaluar RLS. `service_role` no
-- lo necesita, se salta permisos de tabla y RLS por diseno.
grant select on perfiles to authenticated;

-- Los privilegios por defecto del esquema `public` de Supabase dejan TRUNCATE,
-- TRIGGER y REFERENCES a `anon` y `authenticated` incluso con la autoexposicion
-- desactivada. TRUNCATE no pasa por RLS, asi que se revoca explicitamente: la
-- regla "bajas siempre logicas" no debe depender de que PostgREST no exponga esa
-- operacion hoy. TRIGGER y REFERENCES tampoco los necesita ningun caso de uso.
revoke truncate, trigger, references on table perfiles from anon, authenticated;

-- Cada usuario solo lee su propio perfil. No hay politica de insert/update/delete:
-- los perfiles los crea `crear-cliente` con service_role (que salta RLS) y las
-- cuentas de entrenador/administrador se dan de alta desde el panel de Supabase.
create policy "cada usuario ve su propio perfil"
  on perfiles for select
  to authenticated
  using (id = auth.uid());

-- `security definer` para poder leer `perfiles` sin que la propia politica de
-- `perfiles` recursione sobre la consulta. `search_path` fijado para que un
-- esquema en el search_path del llamante no pueda suplantar la tabla.
create function es_entrenador() returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
as $$
  select exists (
    select 1 from perfiles where id = auth.uid() and rol = 'entrenador'
  );
$$;

create function es_administrador() returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
as $$
  select exists (
    select 1 from perfiles where id = auth.uid() and rol = 'administrador'
  );
$$;

-- Postgres concede EXECUTE a PUBLIC por defecto. Se restringe a los roles que
-- de verdad las necesitan: `authenticated` (las evaluan sus politicas RLS) y
-- `service_role` (por si una Edge Function las consulta). `anon` no las usa,
-- porque todas las politicas que las invocan son `to authenticated`.
revoke execute on function es_entrenador() from public;
revoke execute on function es_administrador() from public;
grant execute on function es_entrenador() to authenticated, service_role;
grant execute on function es_administrador() to authenticated, service_role;
