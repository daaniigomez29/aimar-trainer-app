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
series planificadas, fotos de progreso y las tres tablas de los packs); clientes y ejercicios de la
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
usa el enum `dia_semana` porque representa una preferencia recurrente, que se
repite cada semana; no es la fecha de ningún hecho concreto.

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

**No se planifica sobre el calendario**: la sesión se numera dentro de su
planning (Día 1, Día 2…). El entrenador decide *cuántas* sesiones tiene la
semana, no en qué día caen, para que entrenar el jueves lo previsto para el
miércoles no desplace ni duplique nada. Hasta la fase 6 sí tenía `fecha` (date)
planificada y un trigger que la validaba dentro de la semana; lo cambió
`20261004100000_sesiones_por_orden.sql`.

Lo que sí se guarda es `fecha_realizada`: **el día en que el cliente la hizo**,
que es un dato distinto. Es nullable (una sesión no empezada no tiene fecha), la
rellena el trigger de recálculo en el primer registro y la app nunca la escribe.
Hoy no condiciona ninguna regla: solo queda registrada y sirve de eje en las
vistas de progreso (CU-21), donde antes se usaba la fecha planificada.

```sql
create table sesiones_entrenamiento (
  id uuid primary key default gen_random_uuid(),
  planning_id uuid not null references plannings_semanales(id) on delete cascade,
  orden integer not null check (orden > 0),
  nombre text not null,
  fecha_realizada date,
  resultado_registrado boolean not null default false
);

create unique index sesiones_planning_orden_unico
  on sesiones_entrenamiento (planning_id, orden);

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

```

No hay trigger de validación de fecha: sin fecha planificada no hay nada que
validar, y el índice único ya impide dos sesiones con el mismo número. Tanto
`resultado_registrado` como `fecha_realizada` son columnas calculadas y
mantenidas por `recalcular_resultado_sesion` (ver más abajo): la fecha se fija
en el primer ejercicio registrado (con `coalesce`, para que sea la del primer
registro y no la del último) y vuelve a `null` si el cliente deshace todo.

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

Aquí también hay `orden`, por el mismo motivo que en la sesión: varios bloques
comparten la misma sesión sin nada más que los distinga. Se reordena
arrastrando, con `reordenar_bloques` (ver más abajo).

## Ejercicio (biblioteca) y Ejercicio planificado

```sql
-- `fortalecimiento` se anadio en la migracion 20261008090000: trabajo para
-- clientes lesionados, que se planifica **con series**, igual que Fuerza.
create type tipo_ejercicio as enum ('fuerza', 'cardio', 'fortalecimiento');
create type estado_ejercicio as enum ('activo', 'eliminado');

-- Taxonomia muscular (migracion 20261008090100). Dos niveles: el grupo y sus
-- musculos. Sustituye al `grupo_muscular text` libre, con el que convivian
-- "Piernas" e "Isquiotibiales" (region y musculo) al mismo nivel y no habia
-- jerarquia por la que filtrar.
create type grupo_muscular as enum (
  'pierna', 'pecho', 'espalda', 'hombro', 'brazo', 'core'
);

create type musculo as enum (
  'cuadriceps', 'isquiotibiales', 'gluteo', 'aductores', 'abductores', 'gemelo',
  'porcion_esterno_clavicular', 'porcion_esterno_costal',
  'dorsal_ancho', 'trapecio', 'romboides', 'lumbar',
  'deltoides_anterior', 'deltoides_lateral', 'deltoides_posterior',
  'biceps', 'triceps', 'antebrazo',
  'recto_abdominal', 'oblicuos', 'transverso'
);

create table ejercicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  -- Solo se rellena cuando NO hay musculo principal (el cardio: la cinta de
  -- correr es de Pierna sin un musculo concreto). Con principal, el grupo se
  -- **deriva** de el en la app; guardar los dos permitiria el estado
  -- "grupo: Pecho / principal: Cuadriceps", que no detectaria nadie.
  grupo_muscular grupo_muscular,
  musculo_principal musculo,
  musculos_secundarios musculo[] not null default '{}',
  -- Residuo del texto libre anterior, renombrado en vez de convertido para no
  -- perder en silencio los valores que no mapearon. Se elimina en una migracion
  -- posterior, cuando no quede nada sin reclasificar.
  grupo_muscular_antiguo text,
  equipamiento text,
  descripcion text not null,
  video_ejemplo_url text,
  -- Ruta dentro del bucket publico `imagenes-ejercicios` (no la URL: el dominio
  -- cambia entre local y la nube). Anadida en la migracion 20261004090000.
  imagen_ruta text,
  tipo tipo_ejercicio not null,
  estado estado_ejercicio not null default 'activo',
  creado_en timestamptz not null default now()
);

alter table ejercicios
  add constraint grupo_solo_sin_musculo_principal check (
    grupo_muscular is null or musculo_principal is null
  ),
  add constraint principal_fuera_de_secundarios check (
    musculo_principal is null or
    not (musculo_principal = any (musculos_secundarios))
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

-- La pregunta es el MODO de planificacion, no el tipo. Antes eran dos `if` por
-- valor (`= 'cardio'`, `= 'fuerza'`) sin rama por defecto, asi que al anadir
-- 'fortalecimiento' un ejercicio no entraba en ninguno de los dos y habria
-- podido tener minutos Y series a la vez. Un tipo nuevo que no pase por
-- `planifica_con_minutos` falla en voz alta en lugar de colarse por la rama de
-- series (migracion 20261008090200).
create function planifica_con_minutos(p_tipo tipo_ejercicio) returns boolean
  language plpgsql immutable
  set search_path = public, pg_temp
as $$
begin
  case p_tipo
    when 'cardio' then return true;
    when 'fuerza', 'fortalecimiento' then return false;
    else
      raise exception
        'El tipo de ejercicio % no tiene modo de planificacion definido', p_tipo;
  end case;
end;
$$;

-- Version de 20261019090100_cardio_sin_minutos: un cardio planificado puede
-- quedarse sin minutos, igual que una fuerza puede quedarse sin series. Solo se
-- prohibe la contradiccion: minutos en lo que va por series.
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

  if not planifica_con_minutos(v_tipo) then
    if new.minutos_planificados is not null or
       new.minutos_realizados is not null then
      raise exception 'Un ejercicio de % no admite minutos, usa series', v_tipo
        using errcode = 'check_violation';
    end if;
  end if;

  return new;
end;
$$;

create trigger comprobar_tipo_ejercicio_planificado
  before insert or update on ejercicios_planificados
  for each row execute function validar_tipo_ejercicio_planificado();
```

**Cardio sin minutos** (migración `20261019090100_cardio_sin_minutos.sql`,
2026-10-19). Hasta entonces el trigger exigía `minutos_planificados` a todo
cardio. Esa regla, "un ejercicio planificado tiene que decir qué hacer", estaba
partida en dos sitios por una limitación técnica, no por una decisión: los
minutos son una columna de la propia fila y un trigger `before insert` puede
exigirlos, pero las series son filas de otra tabla que se insertan después, así
que la mitad de la fuerza solo vivía en Dart. Con los packs, que permiten dejar
los minutos sin preparar, exigirlos obligaba a inventarse una cifra al aplicar
uno. Ahora el trigger solo prohíbe minutos en lo que va por series. El
formulario de CU-08 sigue pidiendo los minutos al añadir un cardio a mano: lo
único que puede dejarlos vacíos es aplicar un pack que no los traía.

**Lo pasado no se toca** (migración `20261011100000`). `semana_pasada(fecha)`
compara contra el lunes de la semana en curso **en `Europe/Madrid`**, no en UTC:
entre las 00:00 y las 02:00 españolas del lunes, UTC sigue en la semana
anterior y la regla dejaría editar lo que ya es pasado. Un trigger
`before insert or update or delete` en las cinco tablas de planificación la
impone, con tres exenciones:

1. Solo aplica si quien escribe es el entrenador (`es_entrenador()`). Es una
   regla sobre quien planifica, y además el seed —que inserta semanas pasadas
   como `postgres`— seguiría funcionando.
2. En `sesiones_entrenamiento` y `ejercicios_planificados` se dejan pasar los
   cambios que **solo tocan columnas de lo realizado**. Una política RLS no
   puede mirar qué columnas se tocan, así que se comprueba a mano.
3. En `plannings_semanales` se deja pasar el cambio de `estado`: archivar y
   reactivar no cambian el plan.

Van en triggers y no en políticas a propósito: con RLS, un `UPDATE` bloqueado
no da error, deja la petición en 0 filas y la app lo traduciría a "eso ya no
existe". El trigger puede decir por qué.

**Nota de seguridad conocida:** la política de `update` del cliente permite
técnicamente escribir toda la fila, no solo `minutos_realizados`. Se acepta
por ahora vía RLS + interfaz. Pendiente a futuro: separar en columnas con
`GRANT` por columna o mover el registro del cliente a tabla propia si se
necesita mayor garantía.

Esto se comprobó al añadir el reordenado por arrastre (2026-10-04): con solo
RLS, un cliente **sí** podía renumerar los ejercicios de su propio planning
(la prueba devolvía 204 donde se esperaba 403), mientras que con los bloques
se quedaba en 403 porque ahí no tiene política de `update`. Por eso
`reordenar_ejercicios_planificados` comprueba `es_entrenador()` además de
apoyarse en RLS. La nota sigue abierta para el `update` directo a la tabla.

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

### `reordenar_bloques` y `reordenar_ejercicios_planificados` (CU-11, CU-12)

Renumeran `orden` cuando el entrenador mueve un bloque dentro de su sesión o
un ejercicio dentro de su bloque (con flechas desde el 2026-10-19; antes,
arrastrando). Reciben la lista **completa** de ids en el
orden que debe quedar.

No se puede hacer con `update` sueltos: `(sesion_id, orden)` y
`(bloque_id, orden)` son índices únicos y se comprueban fila a fila, así que
cualquier renumeración pasa por un estado intermedio con dos filas en la misma
posición. Las funciones lo resuelven en dos fases dentro de una transacción:
primero restan un millón a todos los órdenes de ese padre (un desplazamiento
uniforme, que mantiene la unicidad) y luego escriben los definitivos.

Validan que la lista traiga todos los elementos y ninguno repetido, y
comprueban `es_entrenador()` (ver la nota de seguridad de "Ejercicio
planificado"). Son `security invoker`, así que RLS sigue aplicando encima.
Después del primer `update` miran `row_count`: con RLS, un `update` prohibido
no da error, simplemente no toca filas, y sin esa comprobación la función se
iría sin excepción y sin haber reordenado nada.

### Vistas `vista_progreso_ejercicios` y `vista_ejercicios_con_registro` (CU-21)

Aplanan la cadena `series_realizadas → ejercicios_planificados → bloques →
sesiones → plannings` y exponen la `fecha_realizada` de la **sesión** (no la de
`fecha_hora_registro`), filtrando las sesiones que aún no la tienen. Incluyen también el cardio, con sus minutos. Se declaran
`with (security_invoker = on)`: sin esa opción la vista correría con los permisos
de su dueño y sería un agujero que puentearía RLS.

### Bucket `imagenes-ejercicios`

El segundo bucket, y el único **público**: la ilustración de un ejercicio no es
dato personal, la ven todos los clientes y se pinta en una lista. Con un bucket
privado habría que firmar una URL por ejercicio cada vez que se abre la
biblioteca, y ninguna se podría cachear. Las políticas sobre `storage.objects`
solo gobiernan la **escritura**: subir, reemplazar y borrar es del entrenador.

### Políticas del bucket `fotos-progreso`

Son RLS normal sobre `storage.objects`, con la ruta
`<cliente_id>/<registro_medidas_id>/<archivo>`: el dueño se resuelve por el primer
segmento, con `(storage.foldername(name))[1] = auth.uid()::text`. El cliente
gestiona lo suyo; el entrenador solo lee; el administrador, sin política, no
accede.

## Renumerado al borrar (2026-10-21)

Migración `20261021090000_renumerar_al_borrar.sql`. Al quitar un ejercicio de
un bloque, o un bloque de una sesión, los demás se renumeran del 1 al N sin
huecos.

**Por qué**: borrar dejaba huecos (1-5 y 7 tras quitar el 6.º de 7), y lo que
calculaba la siguiente posición como "cuántos hay + 1" chocaba con una ocupada.
Le pasó a Aimar en producción. La app ya usa "la más alta + 1", pero en los
bloques el hueco se ve ("BLOQUE 1, BLOQUE 3"), y `aplicar_pack_a_bloque`
contaba filas.

- `renumerar_ejercicios_del_bloque(uuid)` y `renumerar_bloques_de_la_sesion(uuid)`:
  renumeran respetando el orden actual, en dos fases como `reordenar_bloques`
  (aquí apartando hacia arriba, `+ 1000000`). Si no hay huecos no tocan nada.
  `revoke execute ... from public`: la app no puede llamarlas (el cliente
  recibe 403). Así no le dan al cliente, que tiene política de `update` sobre
  sus ejercicios planificados, una forma de tocar el orden.
- Triggers `renumerar_tras_borrar_ejercicios` y `renumerar_tras_borrar_bloques`:
  `after delete ... referencing old table as borrados for each statement`. Uno
  por sentencia, así un borrado múltiple renumera cada padre una sola vez. Se
  saltan los padres que ya no existen, que es lo que pasa en una cascada. Son
  `security definer` porque las funciones están cerradas a la app; `auth.uid()`
  no cambia, así que "lo pasado no se toca" sigue aplicando (y en una semana
  pasada tampoco se puede borrar).
- Un `do` corrige una vez los huecos existentes, también en semanas pasadas
  (corre como el rol de las migraciones, al que no afecta el trigger de "lo
  pasado no se toca").
- `aplicar_pack_a_bloque` calcula la posición con `coalesce(max(orden), 0)` en
  vez de `count(*)`.

**Las sesiones no se renumeran**, a propósito: el "Día 3" que el cliente quizá
ya hizo dejaría de llamarse así.

Probado contra local como el entrenador real (token simulado, RLS y triggers
activos): quitar el 6.º de 7, quitar dos a la vez, quitar el último, quitar un
bloque, cascadas de bloque y de sesión, el cliente sin permiso, la corrección
de huecos existentes y el pack con hueco. Y en `probar_local.sh`, por la API.

## Packs de entrenamiento (RF-25)

Migración `20261019090000_packs_de_entrenamiento.sql`. Plantillas de ejercicios
que el entrenador reutiliza al planificar (entidades 11 a 13 de
`domain-model.md`).

**Tablas propias, no las del planning.** La cadena `bloques →
ejercicios_planificados → series_planificadas` lleva lo necesario para que
alguien entrene y registre (`estado_registro`, `minutos_realizados`,
`fecha_realizada`). Un pack no se entrena ni lo ve ningún cliente. Meter las dos
cosas en las mismas tablas habría obligado a tocar lo que usa el cliente en
producción, incluidas la RPC de registro y las vistas de progreso, para
ahorrarse tres tablas que no comparten ni la mitad de las columnas.

```sql
create table packs (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  tipo tipo_ejercicio not null,
  creado_en timestamptz not null default now(),

  constraint nombre_no_vacio check (length(trim(nombre)) > 0)
);

-- Sin dos packs con el mismo nombre, mirando igual mayusculas y minusculas.
create unique index packs_nombre_unico on packs (lower(trim(nombre)));

create table pack_ejercicios (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references packs(id) on delete cascade,
  -- Sin `on delete cascade`: un ejercicio de la biblioteca nunca se borra
  -- fisicamente, se da de baja.
  ejercicio_id uuid not null references ejercicios(id),
  orden integer not null,
  descanso_seg integer,
  -- Opcional, a diferencia del planning.
  minutos numeric(5, 1),

  constraint orden_positivo check (orden > 0),
  constraint descanso_positivo check (descanso_seg is null or descanso_seg > 0),
  constraint minutos_positivos check (minutos is null or minutos > 0)
);

create unique index pack_ejercicios_orden_unico on pack_ejercicios (pack_id, orden);
create index pack_ejercicios_por_ejercicio on pack_ejercicios (ejercicio_id);

create table pack_series (
  id uuid primary key default gen_random_uuid(),
  pack_ejercicio_id uuid not null
    references pack_ejercicios(id) on delete cascade,
  numero_serie integer not null,
  repeticiones integer not null,
  peso numeric(6, 2),
  rir integer,

  constraint numero_positivo check (numero_serie > 0),
  constraint repeticiones_positivas check (repeticiones > 0),
  constraint peso_positivo check (peso is null or peso > 0),
  constraint rir_rango check (rir is null or rir between 0 and 10)
);

create unique index pack_series_numero_unico
  on pack_series (pack_ejercicio_id, numero_serie);
```

**Permisos y políticas.** Las tres tablas siguen el mismo patrón: RLS activado,
`grant select, insert, update, delete ... to authenticated`, `revoke truncate,
trigger, references ... from anon, authenticated`, y una sola política:

```sql
create policy "solo el entrenador gestiona los packs"
  on packs for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- Igual en pack_ejercicios ("... los ejercicios del pack") y en pack_series
-- ("... las series del pack").
```

Son las únicas tablas, junto a las de planificación, que conceden `delete`:
borrar un pack es físico y se lleva sus ejercicios y sus series en cascada. Lo
ya planificado a partir de él no se toca, porque se copió. Ni el cliente ni el
administrador tienen política, así que no ven ningún pack.

**El tipo del pack manda** (decisión del 2026-10-19: tipo estricto). Dos
triggers lo imponen:

```sql
create function validar_ejercicio_del_pack() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_tipo_pack tipo_ejercicio;
  v_tipo_ejercicio tipo_ejercicio;
begin
  select tipo into v_tipo_pack from packs where id = new.pack_id;
  select tipo into v_tipo_ejercicio from ejercicios where id = new.ejercicio_id;

  if v_tipo_ejercicio is null then
    raise exception 'El ejercicio % no existe', new.ejercicio_id;
  end if;

  if v_tipo_ejercicio <> v_tipo_pack then
    raise exception
      'Este pack es de % y el ejercicio es de %', v_tipo_pack, v_tipo_ejercicio
      using errcode = 'check_violation';
  end if;

  -- Los minutos son de lo que va por minutos. Aqui pueden faltar.
  if not planifica_con_minutos(v_tipo_pack) and new.minutos is not null then
    raise exception 'Un pack de % no lleva minutos, lleva series', v_tipo_pack
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger comprobar_ejercicio_del_pack
  before insert or update on pack_ejercicios
  for each row execute function validar_ejercicio_del_pack();

-- Y al reves: nada de series en un pack de cardio.
create function validar_serie_del_pack() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_tipo tipo_ejercicio;
begin
  select p.tipo into v_tipo
  from pack_ejercicios pe
  join packs p on p.id = pe.pack_id
  where pe.id = new.pack_ejercicio_id;

  if planifica_con_minutos(v_tipo) then
    raise exception 'Un pack de % no lleva series, lleva minutos', v_tipo
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger comprobar_serie_del_pack
  before insert or update on pack_series
  for each row execute function validar_serie_del_pack();
```

Por eso la app no deja cambiar el tipo de un pack al editarlo: dejaría dentro
ejercicios que no encajan.

### `guardar_ejercicio_del_pack` (RPC)

`(p_id, p_pack_id, p_ejercicio_id, p_orden, p_descanso_seg, p_minutos, p_series
jsonb) returns uuid`. Crea (`p_id` nulo) o edita un ejercicio del pack y
**reemplaza sus series**, en una sola transacción. Mismo motivo que
`guardar_ejercicio_planificado`: son tres operaciones y PostgREST abre una
transacción por petición. `p_series` puede venir vacío, porque en un pack las
series son opcionales. Es `security invoker`. Al editar mira si el `update`
tocó la fila: con RLS, uno prohibido no da error, solo deja 0 filas.

### `reordenar_pack_ejercicios` (RPC)

`(p_pack_id, p_ids uuid[]) returns void`. Mismo contrato que
`reordenar_bloques`: la lista **completa** y sin repetidos, comprobación de
`es_entrenador()` y de `row_count`, renumerado en dos fases. Una diferencia: aquí
el aparcamiento intermedio **suma** un millón en vez de restarlo, porque esta
tabla tiene `check (orden > 0)` y restar la violaría a mitad de camino. Las
funciones del planning restan porque sus tablas no llevan ese check. Es uno de
los dos fallos que cazó la verificación contra Supabase local y que no se veían
leyendo el SQL.

### `aplicar_pack_a_bloque` (RPC)

`(p_pack_id, p_bloque_id) returns jsonb`. Copia los ejercicios del pack **al
final** del bloque, con su descanso, sus minutos (solo si el tipo va por
minutos) y sus series, en una transacción: o entran todos o ninguno.

- **Omite los ejercicios dados de baja** (un ejercicio eliminado no se añade a
  bloques nuevos) y devuelve cuántos:
  `{"ejercicios_anadidos": n, "ejercicios_omitidos": m}`. La app lo dice en el
  aviso.
- Un pack sin ningún ejercicio falla con `check_violation` ("Ese pack no tiene
  ejercicios"). Si todos están de baja no falla: devuelve 0 añadidos.
- Si el pack o el bloque no son visibles para quien llama, sale por "ya no
  existe" (`no_data_found`), sin distinguir de "no puedes".
- Es `security invoker`: los `insert` pasan por RLS y por los triggers del
  planning, también el de "lo pasado no se toca".
- **No rellena lo que el pack no traía.** Un cardio sin minutos se queda sin
  minutos. Antes había un `coalesce(..., 20)`, y desapareció con la migración
  siguiente (ver "Ejercicio planificado").
- El tipo del bloque no restringe qué pack se le aplica.

Lo copiado pasa a ser del planning: editar el pack después no lo cambia.

## Notas técnicas pendientes para el futuro

| Nota | Contexto |
| --- | --- |
| Denormalizar `cliente_id` en tablas hijas (sesiones, bloques, ejercicios planificados) si el rendimiento de RLS con varios `join` se volviera un problema real | Por ahora modelo normalizado; con el volumen previsto, impacto despreciable |
| Seguridad a nivel de columna (`GRANT` por columna) para separar "planificado" (entrenador) de "realizado" (cliente) en `ejercicios_planificados` | Revisar si el equipo crece o se necesita mayor garantía |
| ~~Trigger `after update` adicional en `ejercicios_planificados` para completar el recálculo de `resultado_registrado` en cardio~~ | **Resuelto** al cerrar la fase 4 (`propagar_estado_registro`). Ojo: sin `OF estado_registro`, porque `UPDATE OF columna` se dispara según las columnas mencionadas en la sentencia, no según las que cambian |