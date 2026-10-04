-- Fase 5 (2/4) · Check-in semanal de recuperacion.
--
-- Referencia: docs/sql-schema.md ("Check-in semanal de recuperacion") y
-- docs/domain-model.md (entidad 10).
--
-- SIN FK con `registros_medidas` a proposito: comparten `fecha` por convencion de
-- la interfaz (los dos formularios se muestran juntos el dia de control), no por
-- restriccion de dominio. Son dos inserciones independientes y ninguna transaccion
-- las une: si el cliente rellena solo una, esa se guarda.
--
-- Tampoco aqui hay politica para `es_administrador()`.

create table checkins_recuperacion (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null,
  horas_sueno numeric(4, 1) not null,
  estres integer not null,
  agujetas integer not null,
  fatiga integer not null,
  notas text,

  -- Sin tope superior en las horas de sueno, por decision del ERS.
  constraint horas_sueno_positivas check (horas_sueno >= 0),
  -- Escala 1-10, distinta de la del RIR (que va de 0 a 10).
  constraint escalas_1_10 check (
    estres between 1 and 10 and
    agujetas between 1 and 10 and
    fatiga between 1 and 10
  )
);

create unique index checkins_cliente_fecha_unico
  on checkins_recuperacion (cliente_id, fecha);

alter table checkins_recuperacion enable row level security;

-- Sin `delete`, como en medidas y series realizadas: se corrige, no se borra.
grant select, insert, update on checkins_recuperacion to authenticated;
revoke truncate, trigger, references on table checkins_recuperacion
  from anon, authenticated;

create policy "el cliente gestiona sus propios check-in"
  on checkins_recuperacion for all
  to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

create policy "el entrenador consulta los check-in de sus clientes"
  on checkins_recuperacion for select
  to authenticated
  using (es_entrenador());
