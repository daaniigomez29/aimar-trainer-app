-- Fase 4 · Planificacion semanal (1/3): plannings y sesiones.
--
-- Se agrupan en una migracion porque `sesiones_entrenamiento` tiene FK a
-- `plannings_semanales` y su trigger de validacion necesita leerla: no tiene
-- sentido que una exista sin la otra.
--
-- Referencia: docs/sql-schema.md (secciones "Planning semanal" y "Sesion de
-- entrenamiento").

-- ---------------------------------------------------------------------------
-- Planning semanal
-- ---------------------------------------------------------------------------

create type estado_planning as enum ('activo', 'archivado');

create table plannings_semanales (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha_inicio date not null,
  nombre_objetivo text,
  estado estado_planning not null default 'activo',
  creado_en timestamptz not null default now()
);

-- Un planning activo por cliente y semana. Solo bloquea duplicados entre
-- activos: uno archivado con la misma fecha no cuenta como conflicto, para poder
-- rehacer una semana conservando la version anterior.
create unique index plannings_cliente_semana_unico
  on plannings_semanales (cliente_id, fecha_inicio)
  where estado = 'activo';

alter table plannings_semanales enable row level security;

-- A diferencia de clientes y ejercicios, aqui SI se concede `delete`: eliminar un
-- planning es un caso de uso real (CU-13) y arrastra en cascada sus sesiones,
-- bloques y ejercicios planificados.
grant select, insert, update, delete on plannings_semanales to authenticated;
revoke truncate, trigger, references on table plannings_semanales
  from anon, authenticated;

create policy "el cliente ve sus propios plannings"
  on plannings_semanales for select
  to authenticated
  using (cliente_id = auth.uid());

create policy "el entrenador gestiona todos los plannings"
  on plannings_semanales for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- Sesion de entrenamiento
-- ---------------------------------------------------------------------------

create table sesiones_entrenamiento (
  id uuid primary key default gen_random_uuid(),
  planning_id uuid not null references plannings_semanales(id) on delete cascade,
  fecha date not null,
  nombre text not null,
  resultado_registrado boolean not null default false
);

-- Una sesion por fecha dentro de un planning. No hay columna `orden`: se ordenan
-- por `fecha`, que es una fecha real de calendario, no un dia de la semana.
create unique index sesiones_planning_fecha_unico
  on sesiones_entrenamiento (planning_id, fecha);

alter table sesiones_entrenamiento enable row level security;

grant select, insert, update, delete on sesiones_entrenamiento to authenticated;
revoke truncate, trigger, references on table sesiones_entrenamiento
  from anon, authenticated;

create policy "el cliente ve las sesiones de sus plannings"
  on sesiones_entrenamiento for select
  to authenticated
  using (
    exists (
      select 1 from plannings_semanales p
      where p.id = planning_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador gestiona todas las sesiones"
  on sesiones_entrenamiento for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- La fecha de la sesion debe caer dentro de la semana del planning (CU-06).
--
-- `search_path` fijado aunque la funcion no sea `security definer`: se ejecuta con
-- los privilegios de quien escribe, y sin fijarlo una tabla `plannings_semanales`
-- creada en `pg_temp` podria hacer que la comprobacion pasara siempre.
create function validar_fecha_sesion() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_inicio date;
begin
  select fecha_inicio into v_inicio
  from plannings_semanales where id = new.planning_id;

  if v_inicio is null then
    raise exception 'El planning % no existe', new.planning_id;
  end if;

  if new.fecha < v_inicio or new.fecha > v_inicio + 6 then
    raise exception
      'La fecha de la sesion (%) debe estar entre % y %',
      new.fecha, v_inicio, v_inicio + 6
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger comprobar_fecha_sesion
  before insert or update on sesiones_entrenamiento
  for each row execute function validar_fecha_sesion();
