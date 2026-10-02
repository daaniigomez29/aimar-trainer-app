-- Fase 4 · Planificacion semanal (2/3): bloques y ejercicios planificados.
--
-- Referencia: docs/sql-schema.md (secciones "Bloque de ejercicio" y "Ejercicio
-- planificado").

-- ---------------------------------------------------------------------------
-- Bloque de ejercicio
-- ---------------------------------------------------------------------------

create type tipo_bloque as enum (
  'calentamiento', 'fuerza', 'cardio', 'movilidad', 'otro'
);

create table bloques_ejercicio (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references sesiones_entrenamiento(id) on delete cascade,
  tipo tipo_bloque not null,
  orden integer not null,
  notas text
);

-- Aqui si hay `orden`: varios bloques comparten sesion y no tienen fecha propia
-- que los distinga.
create unique index bloques_sesion_orden_unico
  on bloques_ejercicio (sesion_id, orden);

alter table bloques_ejercicio enable row level security;

grant select, insert, update, delete on bloques_ejercicio to authenticated;
revoke truncate, trigger, references on table bloques_ejercicio
  from anon, authenticated;

create policy "el cliente ve los bloques de sus sesiones"
  on bloques_ejercicio for select
  to authenticated
  using (
    exists (
      select 1 from sesiones_entrenamiento s
      join plannings_semanales p on p.id = s.planning_id
      where s.id = sesion_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador gestiona todos los bloques"
  on bloques_ejercicio for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- Ejercicio planificado
-- ---------------------------------------------------------------------------

create table ejercicios_planificados (
  id uuid primary key default gen_random_uuid(),
  bloque_id uuid not null references bloques_ejercicio(id) on delete cascade,
  -- Sin `on delete cascade`: un ejercicio de la biblioteca nunca se borra
  -- fisicamente (baja logica), asi que la referencia no puede quedar huerfana.
  ejercicio_id uuid not null references ejercicios(id),
  orden integer not null,
  descanso_planificado_seg integer,
  minutos_planificados numeric(5, 1),
  minutos_realizados numeric(5, 1),
  estado_registro text not null default 'pendiente'
    check (estado_registro in ('pendiente', 'registrado')),

  constraint descanso_positivo check (
    descanso_planificado_seg is null or descanso_planificado_seg > 0
  ),
  constraint minutos_positivos check (
    (minutos_planificados is null or minutos_planificados > 0) and
    (minutos_realizados is null or minutos_realizados > 0)
  )
);

create unique index ejer_planif_bloque_orden_unico
  on ejercicios_planificados (bloque_id, orden);

alter table ejercicios_planificados enable row level security;

grant select, insert, update, delete on ejercicios_planificados to authenticated;
revoke truncate, trigger, references on table ejercicios_planificados
  from anon, authenticated;

create policy "el cliente ve los ejercicios de sus bloques"
  on ejercicios_planificados for select
  to authenticated
  using (
    exists (
      select 1 from bloques_ejercicio b
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where b.id = bloque_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador gestiona todos los ejercicios planificados"
  on ejercicios_planificados for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- CU-20 (fase 5): el cliente registra sus minutos de cardio. La politica permite
-- tecnicamente escribir toda la fila, no solo `minutos_realizados`; es la "nota de
-- seguridad conocida" de docs/sql-schema.md, aceptada por ahora via RLS +
-- interfaz. Se crea ya para no tener que tocar RLS en la fase siguiente.
create policy "el cliente actualiza minutos realizados (solo cardio)"
  on ejercicios_planificados for update
  to authenticated
  using (
    exists (
      select 1 from bloques_ejercicio b
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where b.id = bloque_id
        and p.cliente_id = auth.uid()
        and p.estado = 'activo'
    )
  )
  with check (true);

-- Fuerza y Cardio son mutuamente excluyentes: Fuerza usa series, Cardio usa
-- minutos. La interfaz ya lo impide, pero esta es la garantia que no depende del
-- cliente.
create function validar_tipo_ejercicio_planificado() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_tipo tipo_ejercicio;
begin
  select tipo into v_tipo from ejercicios where id = new.ejercicio_id;

  if v_tipo is null then
    raise exception 'El ejercicio % no existe', new.ejercicio_id;
  end if;

  if v_tipo = 'cardio' and new.minutos_planificados is null then
    raise exception 'Un ejercicio de cardio requiere minutos_planificados'
      using errcode = 'check_violation';
  end if;

  if v_tipo = 'fuerza' and (
       new.minutos_planificados is not null or
       new.minutos_realizados is not null
     ) then
    raise exception 'Un ejercicio de fuerza no admite minutos, usa series'
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger comprobar_tipo_ejercicio_planificado
  before insert or update on ejercicios_planificados
  for each row execute function validar_tipo_ejercicio_planificado();
