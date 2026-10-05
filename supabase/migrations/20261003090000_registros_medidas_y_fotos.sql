-- Fase 5 (1/4) · Registro de medidas corporales y fotos de progreso.
--
-- Referencia: docs/sql-schema.md ("Registro de medidas corporales y fotos de
-- progreso") y docs/domain-model.md (entidad 9).
--
-- NINGUNA politica para `es_administrador()`, aqui ni en el check-in: el
-- administrador no debe ver estos datos, y con RLS activo la ausencia de politica
-- ya lo bloquea. No es un olvido; no anadir ninguna.

-- ---------------------------------------------------------------------------
-- Registro de medidas corporales
-- ---------------------------------------------------------------------------

create table registros_medidas (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null,
  peso_kg numeric(5, 2) not null,
  pecho_cm numeric(5, 2),
  cintura_cm numeric(5, 2),
  cadera_cm numeric(5, 2),
  cuadriceps_cm numeric(5, 2),
  brazos_cm numeric(5, 2),

  constraint peso_positivo check (peso_kg > 0),
  constraint medidas_positivas check (
    (pecho_cm is null or pecho_cm > 0) and
    (cintura_cm is null or cintura_cm > 0) and
    (cadera_cm is null or cadera_cm > 0) and
    (cuadriceps_cm is null or cuadriceps_cm > 0) and
    (brazos_cm is null or brazos_cm > 0)
  )
);

-- Un registro por cliente y dia: volver a guardar el mismo dia corrige el
-- anterior, no crea otro.
create unique index registros_medidas_cliente_fecha_unico
  on registros_medidas (cliente_id, fecha);

alter table registros_medidas enable row level security;

-- Sin `delete`: lo registrado es historico, igual que las series realizadas. Se
-- corrige con `update`.
grant select, insert, update on registros_medidas to authenticated;
revoke truncate, trigger, references on table registros_medidas
  from anon, authenticated;

create policy "el cliente gestiona sus propios registros de medidas"
  on registros_medidas for all
  to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

create policy "el entrenador consulta las medidas de sus clientes"
  on registros_medidas for select
  to authenticated
  using (es_entrenador());

-- ---------------------------------------------------------------------------
-- Fotos de progreso
-- ---------------------------------------------------------------------------

-- El fichero vive en el bucket privado `fotos-progreso`; aqui solo se guarda su
-- ruta. Nunca una URL: la foto se sirve con una URL firmada que caduca.
create table fotos_progreso (
  id uuid primary key default gen_random_uuid(),
  registro_medidas_id uuid not null
    references registros_medidas(id) on delete cascade,
  ruta_storage text not null,
  subida_en timestamptz not null default now(),

  constraint ruta_no_vacia check (length(trim(ruta_storage)) > 0)
);

-- La misma ruta no puede apuntar a dos filas: si la subida se reintenta, se
-- corrige la fila existente en lugar de duplicarla.
create unique index fotos_progreso_ruta_unica on fotos_progreso (ruta_storage);

alter table fotos_progreso enable row level security;

-- Aqui SI se concede `delete`: quitar una foto subida por error es un caso de uso
-- real, y el fichero del bucket se borra con ella. No hay historico que proteger
-- en una imagen como lo hay en una medida.
grant select, insert, update, delete on fotos_progreso to authenticated;
revoke truncate, trigger, references on table fotos_progreso
  from anon, authenticated;

create policy "el cliente gestiona sus propias fotos"
  on fotos_progreso for all
  to authenticated
  using (
    exists (
      select 1 from registros_medidas r
      where r.id = registro_medidas_id and r.cliente_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from registros_medidas r
      where r.id = registro_medidas_id and r.cliente_id = auth.uid()
    )
  );

create policy "el entrenador ve las fotos de sus clientes"
  on fotos_progreso for select
  to authenticated
  using (es_entrenador());
