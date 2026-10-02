-- Fase 4 · Planificacion semanal (3/3): series planificadas y realizadas.
--
-- `series_realizadas` se crea aqui por integridad referencial con
-- `ejercicios_planificados`, aunque su interfaz y su logica de escritura son de
-- CU-20 (fase 5). Las politicas del cliente tambien se crean ya, para no volver a
-- tocar RLS entonces.
--
-- Referencia: docs/sql-schema.md (seccion "Serie planificada y Serie realizada").

-- ---------------------------------------------------------------------------
-- Serie planificada (la escribe el entrenador)
-- ---------------------------------------------------------------------------

create table series_planificadas (
  id uuid primary key default gen_random_uuid(),
  ejercicio_planificado_id uuid not null
    references ejercicios_planificados(id) on delete cascade,
  numero_serie integer not null,
  repeticiones_planificadas integer not null,
  peso_planificado numeric(6, 2),
  rir_planificado integer,

  constraint repeticiones_positivas check (repeticiones_planificadas > 0),
  constraint peso_positivo check (
    peso_planificado is null or peso_planificado > 0
  ),
  -- RIR (repeticiones en reserva) en escala 0-10.
  constraint rir_rango check (
    rir_planificado is null or rir_planificado between 0 and 10
  )
);

create unique index series_planif_numero_unico
  on series_planificadas (ejercicio_planificado_id, numero_serie);

alter table series_planificadas enable row level security;

grant select, insert, update, delete on series_planificadas to authenticated;
revoke truncate, trigger, references on table series_planificadas
  from anon, authenticated;

-- La lectura se hereda del ejercicio planificado: el cliente ve las suyas y el
-- entrenador todas.
create policy "visible a traves del ejercicio planificado (lectura)"
  on series_planificadas for select
  to authenticated
  using (
    exists (
      select 1 from ejercicios_planificados ep
      join bloques_ejercicio b on b.id = ep.bloque_id
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where ep.id = ejercicio_planificado_id
        and (p.cliente_id = auth.uid() or es_entrenador())
    )
  );

create policy "solo el entrenador escribe series planificadas"
  on series_planificadas for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- Serie realizada (la escribe el cliente, en CU-20 / fase 5)
-- ---------------------------------------------------------------------------

create table series_realizadas (
  id uuid primary key default gen_random_uuid(),
  ejercicio_planificado_id uuid not null
    references ejercicios_planificados(id) on delete cascade,
  numero_serie integer not null,
  repeticiones_realizadas integer not null,
  peso_real numeric(6, 2),
  rir_real integer,
  fecha_hora_registro timestamptz not null default now(),

  constraint repeticiones_positivas check (repeticiones_realizadas > 0),
  constraint peso_positivo check (peso_real is null or peso_real > 0),
  constraint rir_rango check (rir_real is null or rir_real between 0 and 10)
);

create unique index series_realiz_numero_unico
  on series_realizadas (ejercicio_planificado_id, numero_serie);

alter table series_realizadas enable row level security;

-- Sin `delete`: lo que el cliente registro es historico. Puede corregirlo con un
-- update, no borrarlo.
grant select, insert, update on series_realizadas to authenticated;
revoke truncate, trigger, references on table series_realizadas
  from anon, authenticated;

-- El numero de series realizadas no tiene que coincidir con el de planificadas:
-- la diferencia entre lo planificado y lo realizado es la metrica de rendimiento,
-- no un error que haya que impedir.
create policy "el cliente registra sus propias series"
  on series_realizadas for insert
  to authenticated
  with check (
    exists (
      select 1 from ejercicios_planificados ep
      join bloques_ejercicio b on b.id = ep.bloque_id
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where ep.id = ejercicio_planificado_id
        and p.cliente_id = auth.uid()
        and p.estado = 'activo'
    )
  );

create policy "el cliente edita sus propias series"
  on series_realizadas for update
  to authenticated
  using (
    exists (
      select 1 from ejercicios_planificados ep
      join bloques_ejercicio b on b.id = ep.bloque_id
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where ep.id = ejercicio_planificado_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador lee todas las series realizadas"
  on series_realizadas for select
  to authenticated
  using (
    es_entrenador() or
    exists (
      select 1 from ejercicios_planificados ep
      join bloques_ejercicio b on b.id = ep.bloque_id
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where ep.id = ejercicio_planificado_id and p.cliente_id = auth.uid()
    )
  );

-- NOTA: los triggers de recalculo de `estado_registro` y `resultado_registrado`
-- (docs/sql-schema.md, "Triggers de recalculo automatico") NO se crean aqui.
-- Solo tienen efecto cuando el cliente registra resultados, que es CU-20, y el
-- doc deja pendiente completar el caso de cardio con un tercer trigger
-- `after update`. Se resolveran juntos en la fase 5.
