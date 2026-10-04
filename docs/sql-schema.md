# Esquema técnico de base de datos (Supabase/Postgres)

Esquema SQL de referencia: tablas, tipos, restricciones, RLS y triggers.
Corresponde 1:1 al modelo de `domain-model.md`. Vive versionado como
migraciones en `supabase/migrations/`; este archivo es la vista de conjunto.

**Sobre los `GRANT`:** el proyecto de Supabase tiene desactivada la opción
"Automatically expose new tables" (recomendado por seguridad), así que cada
tabla necesita su propio `grant ... to authenticated` explícito, además de
`enable row level security` y sus políticas. Sin el `GRANT`, PostgREST
deniega el acceso a la tabla antes de que RLS llegue a evaluarse — es un
paso obligatorio, no opcional.

`service_role` **también necesita `GRANT`** en las tablas que usen las Edge
Functions. Ese rol se salta RLS (tiene `BYPASSRLS`), pero **no** los privilegios
de tabla de Postgres: sin el `GRANT` recibe `permission denied for table`. Se le
concede solo lo que usa y nunca `delete`: para deshacer un alta a medias basta
`auth.admin.deleteUser`, que cascadea por la FK a `auth.users`.
Ninguna tabla concede `delete` salvo las que tienen un caso de uso real de
borrado físico (plannings, sesiones, bloques, ejercicios planificados,
series planificadas, fotos de progreso); clientes y ejercicios de la
biblioteca nunca conceden `delete`, porque su baja es siempre lógica.

## Base: perfiles y funciones auxiliares

```sql
create type rol_usuario as enum ('administrador', 'entrenador', 'cliente');

create table perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  rol rol_usuario not null,
  creado_en timestamptz not null default now()
);

alter table perfiles enable row level security;

-- Necesario si "Automatically expose new tables" está desactivada en el proyecto:
-- sin este GRANT, PostgREST deniega el acceso antes de evaluar RLS.
grant select on perfiles to authenticated;

create policy "cada usuario ve su propio perfil"
  on perfiles for select
  using (id = auth.uid());

create function es_entrenador() returns boolean
  language sql stable security definer as $$
  select exists (select 1 from perfiles where id = auth.uid() and rol = 'entrenador');
$$;

create function es_administrador() returns boolean
  language sql stable security definer as $$
  select exists (select 1 from perfiles where id = auth.uid() and rol = 'administrador');
$$;
```

## Cliente

```sql
create type estado_cliente as enum ('activo', 'baja');
create type dia_semana as enum ('lunes','martes','miercoles','jueves','viernes','sabado','domingo');

create table clientes (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  correo text not null,
  fecha_nacimiento date,
  altura_cm numeric(5,2),
  peso_inicial_kg numeric(5,2),
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

create unique index clientes_correo_activo_unico
  on clientes (lower(correo))
  where estado = 'activo';

alter table clientes enable row level security;

grant select, insert, update on clientes to authenticated;

create policy "el cliente ve su propia ficha"
  on clientes for select
  using (id = auth.uid());

create policy "el entrenador ve y gestiona todas las fichas"
  on clientes for all
  using (es_entrenador())
  with check (es_entrenador());

create policy "el cliente edita datos limitados de su ficha"
  on clientes for update
  using (id = auth.uid())
  with check (id = auth.uid() and estado = 'activo');
```

`id` es el mismo `auth.users.id` (1:1, sin id propio duplicado). La
unicidad de correo solo aplica a clientes activos. `dia_control_preferido`
usa el enum `dia_semana` porque representa una preferencia recurrente, a
diferencia de la fecha real de una sesión (ver más abajo).

## Planning semanal

```sql
create type estado_planning as enum ('activo', 'archivado');

create table plannings_semanales (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha_inicio date not null,
  nombre_objetivo text,
  estado estado_planning not null default 'activo',
  creado_en timestamptz not null default now()
);

create unique index plannings_cliente_semana_unico
  on plannings_semanales (cliente_id, fecha_inicio)
  where estado = 'activo';

alter table plannings_semanales enable row level security;

grant select, insert, update, delete on plannings_semanales to authenticated;

create policy "el cliente ve sus propios plannings"
  on plannings_semanales for select
  using (cliente_id = auth.uid());

create policy "el entrenador gestiona todos los plannings"
  on plannings_semanales for all
  using (es_entrenador())
  with check (es_entrenador());
```

El índice único de "un planning activo por cliente y semana" solo bloquea
duplicados entre plannings activos; uno archivado con la misma
`fecha_inicio` no cuenta como conflicto.

## Sesión de entrenamiento

Se planifica sobre calendario real: usa `fecha` (date), no un día de semana
suelto.

```sql
create table sesiones_entrenamiento (
  id uuid primary key default gen_random_uuid(),
  planning_id uuid not null references plannings_semanales(id) on delete cascade,
  fecha date not null,
  nombre text not null,
  resultado_registrado boolean not null default false
);

create unique index sesiones_planning_fecha_unico
  on sesiones_entrenamiento (planning_id, fecha);

alter table sesiones_entrenamiento enable row level security;

grant select, insert, update, delete on sesiones_entrenamiento to authenticated;

create policy "el cliente ve las sesiones de sus plannings"
  on sesiones_entrenamiento for select
  using (
    exists (
      select 1 from plannings_semanales p
      where p.id = planning_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador gestiona todas las sesiones"
  on sesiones_entrenamiento for all
  using (es_entrenador())
  with check (es_entrenador());

create function validar_fecha_sesion() returns trigger
  language plpgsql as $$
declare
  v_inicio date;
begin
  select fecha_inicio into v_inicio from plannings_semanales where id = new.planning_id;
  if new.fecha < v_inicio or new.fecha > v_inicio + 6 then
    raise exception 'La fecha de la sesión debe estar dentro de la semana del planning';
  end if;
  return new;
end;
$$;

create trigger comprobar_fecha_sesion
  before insert or update on sesiones_entrenamiento
  for each row execute function validar_fecha_sesion();
```

No hay `orden`: se ordenan por `fecha`. `resultado_registrado` es una
columna calculada y mantenida por triggers (ver más abajo).

## Bloque de ejercicio

```sql
create type tipo_bloque as enum ('calentamiento', 'fuerza', 'cardio', 'movilidad', 'otro');

create table bloques_ejercicio (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references sesiones_entrenamiento(id) on delete cascade,
  tipo tipo_bloque not null,
  orden integer not null,
  notas text
);

create unique index bloques_sesion_orden_unico
  on bloques_ejercicio (sesion_id, orden);

alter table bloques_ejercicio enable row level security;

grant select, insert, update, delete on bloques_ejercicio to authenticated;

create policy "el cliente ve los bloques de sus sesiones"
  on bloques_ejercicio for select
  using (
    exists (
      select 1 from sesiones_entrenamiento s
      join plannings_semanales p on p.id = s.planning_id
      where s.id = sesion_id and p.cliente_id = auth.uid()
    )
  );

create policy "el entrenador gestiona todos los bloques"
  on bloques_ejercicio for all
  using (es_entrenador())
  with check (es_entrenador());
```

Aquí sí se mantiene `orden`: varios bloques comparten la misma sesión sin
una fecha propia que los distinga.

## Ejercicio (biblioteca) y Ejercicio planificado

```sql
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

grant select, insert, update on ejercicios to authenticated;

create policy "cualquier usuario autenticado lee la biblioteca"
  on ejercicios for select
  using (auth.role() = 'authenticated');

create policy "solo el entrenador gestiona la biblioteca"
  on ejercicios for insert
  with check (es_entrenador());

create policy "solo el entrenador edita la biblioteca"
  on ejercicios for update
  using (es_entrenador())
  with check (es_entrenador());
```

Sin permiso de `delete`: la baja de un ejercicio siempre es `update` a
`estado = 'eliminado'`.

```sql
create table ejercicios_planificados (
  id uuid primary key default gen_random_uuid(),
  bloque_id uuid not null references bloques_ejercicio(id) on delete cascade,
  ejercicio_id uuid not null references ejercicios(id),
  orden integer not null,
  descanso_planificado_seg integer,
  minutos_planificados numeric(5,1),
  minutos_realizados numeric(5,1),
  estado_registro text not null default 'pendiente'
    check (estado_registro in ('pendiente', 'registrado')),

  constraint descanso_positivo check (descanso_planificado_seg is null or descanso_planificado_seg > 0),
  constraint minutos_positivos check (
    (minutos_planificados is null or minutos_planificados > 0) and
    (minutos_realizados is null or minutos_realizados > 0)
  )
);

create unique index ejer_planif_bloque_orden_unico
  on ejercicios_planificados (bloque_id, orden);

alter table ejercicios_planificados enable row level security;

grant select, insert, update, delete on ejercicios_planificados to authenticated;

create policy "el cliente ve los ejercicios de sus bloques"
  on ejercicios_planificados for select
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
  using (es_entrenador())
  with check (es_entrenador());

create policy "el cliente actualiza minutos realizados (solo cardio)"
  on ejercicios_planificados for update
  using (
    exists (
      select 1 from bloques_ejercicio b
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where b.id = bloque_id and p.cliente_id = auth.uid() and p.estado = 'activo'
    )
  )
  with check (true);

create function validar_tipo_ejercicio_planificado() returns trigger
  language plpgsql as $$
declare
  v_tipo tipo_ejercicio;
begin
  select tipo into v_tipo from ejercicios where id = new.ejercicio_id;

  if v_tipo = 'cardio' and (new.minutos_planificados is null) then
    raise exception 'Un ejercicio de cardio requiere minutos_planificados';
  end if;

  if v_tipo = 'fuerza' and (new.minutos_planificados is not null or new.minutos_realizados is not null) then
    raise exception 'Un ejercicio de fuerza no admite minutos, usa series';
  end if;

  return new;
end;
$$;

create trigger comprobar_tipo_ejercicio_planificado
  before insert or update on ejercicios_planificados
  for each row execute function validar_tipo_ejercicio_planificado();
```

**Nota de seguridad conocida:** la política de `update` del cliente permite
técnicamente escribir toda la fila, no solo `minutos_realizados`. Se acepta
por ahora vía RLS + interfaz. Pendiente a futuro: separar en columnas con
`GRANT` por columna o mover el registro del cliente a tabla propia si se
necesita mayor garantía.

## Serie planificada y Serie realizada

```sql
create table series_planificadas (
  id uuid primary key default gen_random_uuid(),
  ejercicio_planificado_id uuid not null references ejercicios_planificados(id) on delete cascade,
  numero_serie integer not null,
  repeticiones_planificadas integer not null,
  peso_planificado numeric(6,2),
  rir_planificado integer,

  constraint repeticiones_positivas check (repeticiones_planificadas > 0),
  constraint peso_positivo check (peso_planificado is null or peso_planificado > 0),
  constraint rir_rango check (rir_planificado is null or rir_planificado between 0 and 10)
);

create unique index series_planif_numero_unico
  on series_planificadas (ejercicio_planificado_id, numero_serie);

alter table series_planificadas enable row level security;

grant select, insert, update, delete on series_planificadas to authenticated;

create policy "visible a través del ejercicio planificado (lectura)"
  on series_planificadas for select
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
  using (es_entrenador())
  with check (es_entrenador());
```

```sql
create table series_realizadas (
  id uuid primary key default gen_random_uuid(),
  ejercicio_planificado_id uuid not null references ejercicios_planificados(id) on delete cascade,
  numero_serie integer not null,
  repeticiones_realizadas integer not null,
  peso_real numeric(6,2),
  rir_real integer,
  fecha_hora_registro timestamptz not null default now(),

  constraint repeticiones_positivas check (repeticiones_realizadas > 0),
  constraint peso_positivo check (peso_real is null or peso_real > 0),
  constraint rir_rango check (rir_real is null or rir_real between 0 and 10)
);

create unique index series_realiz_numero_unico
  on series_realizadas (ejercicio_planificado_id, numero_serie);

alter table series_realizadas enable row level security;

grant select, insert, update on series_realizadas to authenticated;

create policy "el cliente registra sus propias series"
  on series_realizadas for insert
  with check (
    exists (
      select 1 from ejercicios_planificados ep
      join bloques_ejercicio b on b.id = ep.bloque_id
      join sesiones_entrenamiento s on s.id = b.sesion_id
      join plannings_semanales p on p.id = s.planning_id
      where ep.id = ejercicio_planificado_id
        and p.cliente_id = auth.uid() and p.estado = 'activo'
    )
  );

create policy "el cliente edita sus propias series"
  on series_realizadas for update
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
```

RIR (repeticiones en reserva) en escala 0–10, tanto planificado como real.
Los valores del cliente son independientes de los del entrenador.

## Triggers de recálculo automático

```sql
create function recalcular_resultado_sesion(p_sesion_id uuid) returns void
  language plpgsql as $$
begin
  update sesiones_entrenamiento
  set resultado_registrado = not exists (
    select 1
    from bloques_ejercicio b
    join ejercicios_planificados ep on ep.bloque_id = b.id
    where b.sesion_id = p_sesion_id and ep.estado_registro = 'pendiente'
  )
  where id = p_sesion_id;
end;
$$;

create function recalcular_estado_registro_por_series() returns trigger
  language plpgsql as $$
declare
  v_ep_id uuid := coalesce(new.ejercicio_planificado_id, old.ejercicio_planificado_id);
  v_sesion_id uuid;
begin
  update ejercicios_planificados
  set estado_registro = case
    when exists (select 1 from series_realizadas where ejercicio_planificado_id = v_ep_id)
    then 'registrado' else 'pendiente' end
  where id = v_ep_id;

  select s.id into v_sesion_id
  from ejercicios_planificados ep
  join bloques_ejercicio b on b.id = ep.bloque_id
  join sesiones_entrenamiento s on s.id = b.sesion_id
  where ep.id = v_ep_id;

  perform recalcular_resultado_sesion(v_sesion_id);
  return null;
end;
$$;

create trigger recalcular_tras_serie_realizada
  after insert or update or delete on series_realizadas
  for each row execute function recalcular_estado_registro_por_series();

create function recalcular_estado_registro_por_minutos() returns trigger
  language plpgsql as $$
begin
  if new.minutos_realizados is not null and new.minutos_realizados <> coalesce(old.minutos_realizados, -1) then
    new.estado_registro := 'registrado';
  end if;
  return new;
end;
$$;

create trigger recalcular_tras_minutos_cardio
  before update on ejercicios_planificados
  for each row execute function recalcular_estado_registro_por_minutos();
```

**Pendiente de implementación fina:** el trigger de minutos (Cardio) cambia
`estado_registro` en la misma fila (`before update`), pero no puede invocar
`recalcular_resultado_sesion` antes de que el cambio esté confirmado. Falta
un tercer trigger `after update` sobre `ejercicios_planificados` que
detecte el cambio de `estado_registro` y entonces sí llame a
`recalcular_resultado_sesion`.

## Registro de medidas corporales y fotos de progreso

```sql
create table registros_medidas (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null,
  peso_kg numeric(5,2) not null,
  pecho_cm numeric(5,2),
  cintura_cm numeric(5,2),
  cadera_cm numeric(5,2),
  cuadriceps_cm numeric(5,2),
  brazos_cm numeric(5,2),

  constraint peso_positivo check (peso_kg > 0),
  constraint medidas_positivas check (
    (pecho_cm is null or pecho_cm > 0) and
    (cintura_cm is null or cintura_cm > 0) and
    (cadera_cm is null or cadera_cm > 0) and
    (cuadriceps_cm is null or cuadriceps_cm > 0) and
    (brazos_cm is null or brazos_cm > 0)
  )
);

create unique index registros_medidas_cliente_fecha_unico
  on registros_medidas (cliente_id, fecha);

alter table registros_medidas enable row level security;

grant select, insert, update on registros_medidas to authenticated;

create policy "el cliente gestiona sus propios registros de medidas"
  on registros_medidas for all
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

create policy "el entrenador consulta las medidas de sus clientes"
  on registros_medidas for select
  using (es_entrenador());

create table fotos_progreso (
  id uuid primary key default gen_random_uuid(),
  registro_medidas_id uuid not null references registros_medidas(id) on delete cascade,
  ruta_storage text not null,
  subida_en timestamptz not null default now()
);

alter table fotos_progreso enable row level security;

grant select, insert, update, delete on fotos_progreso to authenticated;

create policy "el cliente gestiona sus propias fotos"
  on fotos_progreso for all
  using (
    exists (select 1 from registros_medidas r where r.id = registro_medidas_id and r.cliente_id = auth.uid())
  )
  with check (
    exists (select 1 from registros_medidas r where r.id = registro_medidas_id and r.cliente_id = auth.uid())
  );

create policy "el entrenador ve las fotos de sus clientes"
  on fotos_progreso for select
  using (es_entrenador());
```

Las fotos residen en un bucket privado de Supabase Storage; `ruta_storage`
solo guarda la referencia. Las políticas del bucket se definen aparte, al
configurar Storage.

## Check-in semanal de recuperación

```sql
create table checkins_recuperacion (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null,
  horas_sueno numeric(4,1) not null,
  estres integer not null,
  agujetas integer not null,
  fatiga integer not null,
  notas text,

  constraint horas_sueno_positivas check (horas_sueno >= 0),
  constraint escalas_1_10 check (
    estres between 1 and 10 and
    agujetas between 1 and 10 and
    fatiga between 1 and 10
  )
);

create unique index checkins_cliente_fecha_unico
  on checkins_recuperacion (cliente_id, fecha);

alter table checkins_recuperacion enable row level security;

grant select, insert, update on checkins_recuperacion to authenticated;

create policy "el cliente gestiona sus propios check-in"
  on checkins_recuperacion for all
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

create policy "el entrenador consulta los check-in de sus clientes"
  on checkins_recuperacion for select
  using (es_entrenador());
```

`horas_sueno` sin límite superior por ahora. `registros_medidas` y
`checkins_recuperacion` no comparten tabla ni FK entre sí; el front hace
dos inserciones independientes una vez completados ambos formularios el
mismo día, sin transacción que las una a nivel de base de datos.

Ninguna tabla de esta sección (medidas, fotos, check-in, series realizadas)
tiene política para `es_administrador()`: la ausencia de política ya
bloquea el acceso del administrador por defecto.

## Añadidos de la fase 5 (no estaban en el diseño original)

Lo que las migraciones de la fase 5 incorporan sobre lo descrito arriba.

### `registrar_resultado_ejercicio` (RPC de CU-20)

Guarda el resultado de un ejercicio en **una sola transacción**: las series si es
Fuerza, los minutos si es Cardio, nunca las dos cosas. Es `security invoker`, así
que RLS sigue aplicando dentro y no amplía permisos a nadie. Mismo motivo que
`guardar_ejercicio_planificado`: PostgREST abre una transacción por petición.

A diferencia de aquélla, aquí **no se borra y se vuelve a insertar**, sino
`insert ... on conflict (ejercicio_planificado_id, numero_serie) do update`: a
`series_realizadas` no se le concede `delete` a propósito. Consecuencia conocida:
si el cliente registra 3 series y luego corrige a 2, la tercera sigue ahí.

### Vistas `vista_progreso_ejercicios` y `vista_ejercicios_con_registro` (CU-21)

Aplanan la cadena `series_realizadas → ejercicios_planificados → bloques →
sesiones → plannings` y exponen la fecha de la **sesión** (no la de
`fecha_hora_registro`). Incluyen también el cardio, con sus minutos. Se declaran
`with (security_invoker = on)`: sin esa opción la vista correría con los permisos
de su dueño y sería un agujero que puentearía RLS.

### Políticas del bucket `fotos-progreso`

Son RLS normal sobre `storage.objects`, con la ruta
`<cliente_id>/<registro_medidas_id>/<archivo>`: el dueño se resuelve por el primer
segmento, con `(storage.foldername(name))[1] = auth.uid()::text`. El cliente
gestiona lo suyo; el entrenador solo lee; el administrador, sin política, no
accede.

## Notas técnicas pendientes para el futuro

| Nota | Contexto |
| --- | --- |
| Denormalizar `cliente_id` en tablas hijas (sesiones, bloques, ejercicios planificados) si el rendimiento de RLS con varios `join` se volviera un problema real | Por ahora modelo normalizado; con el volumen previsto, impacto despreciable |
| Seguridad a nivel de columna (`GRANT` por columna) para separar "planificado" (entrenador) de "realizado" (cliente) en `ejercicios_planificados` | Revisar si el equipo crece o se necesita mayor garantía |
| ~~Trigger `after update` adicional en `ejercicios_planificados` para completar el recálculo de `resultado_registrado` en cardio~~ | **Resuelto** al cerrar la fase 4 (`propagar_estado_registro`). Ojo: sin `OF estado_registro`, porque `UPDATE OF columna` se dispara según las columnas mencionadas en la sentencia, no según las que cambian |