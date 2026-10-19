-- Packs de entrenamiento: plantillas de ejercicios que el entrenador reutiliza.
--
-- QUE ES UN PACK: un nombre, un tipo (Fuerza, Cardio o Fortalecimiento) y un
-- conjunto de ejercicios de la biblioteca, cada uno con sus series o sus minutos
-- **preconfigurados y opcionales**. Se aplica a un bloque de una sesion y a
-- partir de ahi lo copiado es del planning: editar el pack despues no cambia lo
-- que ya se planifico.
--
-- POR QUE TABLAS PROPIAS Y NO REUTILIZAR LAS DEL PLANNING: la cadena
-- `bloques -> ejercicios_planificados -> series_planificadas` existe porque
-- alguien va a entrenar eso, y lo lleva encima: `estado_registro`,
-- `minutos_realizados`, `fecha_realizada`. Un pack es una **plantilla**: no se
-- entrena, no se registra y no la ve ningun cliente. Meter las dos cosas en las
-- mismas tablas obligaria a tocar lo que hoy usa el cliente en produccion
-- —incluida la RPC de registro y las vistas de progreso— para ahorrar tres
-- tablas que no comparten ni la mitad de las columnas.
--
-- SOLO EL ENTRENADOR. Ni el cliente ni el administrador: son su herramienta de
-- trabajo, no informacion de nadie mas.

-- ---------------------------------------------------------------------------
-- El pack
-- ---------------------------------------------------------------------------
create table packs (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  tipo tipo_ejercicio not null,
  creado_en timestamptz not null default now(),

  constraint nombre_no_vacio check (length(trim(nombre)) > 0)
);

-- Sin dos packs con el mismo nombre, mirando igual mayusculas y minusculas: son
-- pocos y se eligen por el nombre en una lista.
create unique index packs_nombre_unico on packs (lower(trim(nombre)));

alter table packs enable row level security;
grant select, insert, update, delete on packs to authenticated;
revoke truncate, trigger, references on table packs from anon, authenticated;

create policy "solo el entrenador gestiona los packs"
  on packs for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- Los ejercicios del pack
-- ---------------------------------------------------------------------------
create table pack_ejercicios (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references packs(id) on delete cascade,
  -- Sin `on delete cascade`, como en `ejercicios_planificados`: un ejercicio de
  -- la biblioteca nunca se borra fisicamente, se da de baja.
  ejercicio_id uuid not null references ejercicios(id),
  orden integer not null,
  descanso_seg integer,
  -- **Opcional**, a diferencia del planning: un pack puede traer solo la lista
  -- de ejercicios, sin nada preconfigurado.
  minutos numeric(5, 1),

  constraint orden_positivo check (orden > 0),
  constraint descanso_positivo check (descanso_seg is null or descanso_seg > 0),
  constraint minutos_positivos check (minutos is null or minutos > 0)
);

create unique index pack_ejercicios_orden_unico on pack_ejercicios (pack_id, orden);
create index pack_ejercicios_por_ejercicio on pack_ejercicios (ejercicio_id);

alter table pack_ejercicios enable row level security;
grant select, insert, update, delete on pack_ejercicios to authenticated;
revoke truncate, trigger, references on table pack_ejercicios
  from anon, authenticated;

create policy "solo el entrenador gestiona los ejercicios del pack"
  on pack_ejercicios for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- Las series preconfiguradas
-- ---------------------------------------------------------------------------
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
  -- Misma escala que en el planning (regla de dominio).
  constraint rir_rango check (rir is null or rir between 0 and 10)
);

create unique index pack_series_numero_unico
  on pack_series (pack_ejercicio_id, numero_serie);

alter table pack_series enable row level security;
grant select, insert, update, delete on pack_series to authenticated;
revoke truncate, trigger, references on table pack_series
  from anon, authenticated;

create policy "solo el entrenador gestiona las series del pack"
  on pack_series for all
  to authenticated
  using (es_entrenador())
  with check (es_entrenador());

-- ---------------------------------------------------------------------------
-- El tipo del pack manda: todos sus ejercicios son de ese tipo
-- ---------------------------------------------------------------------------
--
-- Decision del 2026-10-19: tipo estricto. Un pack de "Fuerza" con un cardio
-- dentro dejaria el tipo del pack sin significar nada, y "preconfigurar series
-- o minutos" pasaria a depender de cada ejercicio en vez del pack.
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

  -- Los minutos son de lo que va por minutos, igual que en el planning. La
  -- diferencia es que aqui pueden faltar.
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

-- ---------------------------------------------------------------------------
-- Guardar un ejercicio del pack con sus series, de una pieza
-- ---------------------------------------------------------------------------
--
-- Mismo motivo que `guardar_ejercicio_planificado`: son tres operaciones
-- (upsert, borrar las series de antes, insertar las nuevas) y PostgREST abre una
-- transaccion por peticion. O entra todo, o no entra nada.
create function guardar_ejercicio_del_pack(
  -- `null` para crear; con valor, edita ese.
  p_id uuid,
  p_pack_id uuid,
  p_ejercicio_id uuid,
  p_orden integer,
  p_descanso_seg integer,
  p_minutos numeric,
  -- [{"numero_serie": 1, "repeticiones": 10, "peso": 60, "rir": 2}, ...]
  -- Vacio tambien vale: las series son opcionales en un pack.
  p_series jsonb
) returns uuid
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if p_id is null then
    insert into pack_ejercicios (
      pack_id, ejercicio_id, orden, descanso_seg, minutos
    )
    values (p_pack_id, p_ejercicio_id, p_orden, p_descanso_seg, p_minutos)
    returning id into v_id;
  else
    update pack_ejercicios
    set ejercicio_id = p_ejercicio_id,
        orden = p_orden,
        descanso_seg = p_descanso_seg,
        minutos = p_minutos
    where id = p_id
    returning id into v_id;

    -- Con RLS, un update prohibido no da error: no toca filas (trampa 8).
    if v_id is null then
      raise exception 'Ese ejercicio del pack ya no existe'
        using errcode = 'no_data_found';
    end if;

    delete from pack_series where pack_ejercicio_id = v_id;
  end if;

  insert into pack_series (
    pack_ejercicio_id, numero_serie, repeticiones, peso, rir
  )
  select
    v_id,
    (serie->>'numero_serie')::integer,
    (serie->>'repeticiones')::integer,
    (serie->>'peso')::numeric,
    (serie->>'rir')::integer
  from jsonb_array_elements(coalesce(p_series, '[]'::jsonb)) as serie;

  return v_id;
end;
$$;

revoke execute on function guardar_ejercicio_del_pack(
  uuid, uuid, uuid, integer, integer, numeric, jsonb
) from public;
grant execute on function guardar_ejercicio_del_pack(
  uuid, uuid, uuid, integer, integer, numeric, jsonb
) to authenticated;

-- ---------------------------------------------------------------------------
-- Reordenar los ejercicios del pack
-- ---------------------------------------------------------------------------
--
-- Mismo renumerado en dos fases que `reordenar_bloques`: el indice unico de
-- `(pack_id, orden)` se comprueba fila a fila y cualquier orden de `update` pasa
-- por un estado con dos filas compartiendo numero. Se apartan todas a un rango
-- imposible y despues se escriben las definitivas.
--
-- OJO, AQUI SE APARTA HACIA ARRIBA y no hacia abajo como en las funciones del
-- planning: esta tabla tiene `check (orden > 0)` y restar un millon la viola a
-- mitad de camino. Las de bloques y ejercicios planificados no llevan ese check,
-- por eso alli funciona restando. Mantener la comprobacion vale mas que la
-- simetria: un orden negativo siempre es un error.
create function reordenar_pack_ejercicios(
  p_pack_id uuid,
  -- Todos los del pack, una sola vez cada uno: renumera del 1 al N.
  p_ids uuid[]
) returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_cuantos integer := coalesce(array_length(p_ids, 1), 0);
  v_tocadas integer;
begin
  if not es_entrenador() then
    raise exception 'Solo el entrenador gestiona los packs'
      using errcode = 'insufficient_privilege';
  end if;

  if v_cuantos = 0 then
    raise exception 'No hay ejercicios que reordenar'
      using errcode = 'check_violation';
  end if;

  if v_cuantos <> (select count(distinct id) from unnest(p_ids) as t(id)) then
    raise exception 'La lista trae repetidos' using errcode = 'check_violation';
  end if;

  if v_cuantos <> (
    select count(*) from pack_ejercicios
    where pack_id = p_pack_id and id = any(p_ids)
  ) or v_cuantos <> (
    select count(*) from pack_ejercicios where pack_id = p_pack_id
  ) then
    raise exception 'La lista debe traer todos los ejercicios del pack'
      using errcode = 'check_violation';
  end if;

  update pack_ejercicios set orden = orden + 1000000 where pack_id = p_pack_id;

  get diagnostics v_tocadas = row_count;
  if v_tocadas <> v_cuantos then
    raise exception 'No se ha podido reordenar: sin permiso sobre ese pack'
      using errcode = 'insufficient_privilege';
  end if;

  update pack_ejercicios pe
  set orden = nuevo.posicion
  from (
    select id, ordinalidad::integer as posicion
    from unnest(p_ids) with ordinality as t(id, ordinalidad)
  ) as nuevo
  where pe.id = nuevo.id and pe.pack_id = p_pack_id;

  -- Red de seguridad: ninguna fila puede quedarse aparcada.
  if exists (
    select 1 from pack_ejercicios where pack_id = p_pack_id and orden > 1000000
  ) then
    raise exception 'No se ha podido reordenar: sin permiso sobre ese pack'
      using errcode = 'insufficient_privilege';
  end if;
end;
$$;

revoke execute on function reordenar_pack_ejercicios(uuid, uuid[]) from public;
grant execute on function reordenar_pack_ejercicios(uuid, uuid[])
  to authenticated;

-- ---------------------------------------------------------------------------
-- Aplicar un pack a un bloque
-- ---------------------------------------------------------------------------
--
-- Copia los ejercicios del pack **al final** del bloque, con sus series. Es el
-- mismo problema que duplicar una semana: decenas de inserts anidados que tienen
-- que ir todos o ninguno.
--
-- QUE SE OMITE: los ejercicios dados de baja. La regla de dominio dice que un
-- ejercicio eliminado no se anade a bloques nuevos, y aplicar un pack es
-- anadirlo. Se devuelve cuantos, para que la app lo diga en vez de dejar huecos
-- sin explicacion.
--
-- LOS MINUTOS DEL CARDIO: se copian tal cual, y si el pack no los traia el
-- ejercicio planificado se queda sin ellos, igual que uno de fuerza se queda
-- sin series. Lo permite la migracion siguiente, que relaja
-- `validar_tipo_ejercicio_planificado`. Antes se rellenaba con 20 por defecto,
-- y era inventarse un dato que el entrenador no habia puesto.
create function aplicar_pack_a_bloque(
  p_pack_id uuid,
  p_bloque_id uuid
) returns jsonb
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_orden integer;
  v_anadidos integer := 0;
  v_omitidos integer := 0;
  v_nuevo uuid;
  v_ejercicio record;
begin
  -- Los dos `select` pasan por RLS: si el pack o el bloque no son visibles para
  -- quien llama, esto sale por "ya no existe" sin distinguir de "no puedes".
  if not exists (select 1 from packs where id = p_pack_id) then
    raise exception 'Ese pack ya no existe' using errcode = 'no_data_found';
  end if;
  if not exists (select 1 from bloques_ejercicio where id = p_bloque_id) then
    raise exception 'Ese bloque ya no existe' using errcode = 'no_data_found';
  end if;

  select count(*) into v_orden
  from ejercicios_planificados where bloque_id = p_bloque_id;

  select count(*) into v_omitidos
  from pack_ejercicios pe
  join ejercicios e on e.id = pe.ejercicio_id
  where pe.pack_id = p_pack_id and e.estado <> 'activo';

  for v_ejercicio in
    select pe.id, pe.ejercicio_id, pe.descanso_seg, pe.minutos,
           planifica_con_minutos(e.tipo) as por_minutos
    from pack_ejercicios pe
    join ejercicios e on e.id = pe.ejercicio_id
    where pe.pack_id = p_pack_id and e.estado = 'activo'
    order by pe.orden
  loop
    v_orden := v_orden + 1;

    insert into ejercicios_planificados (
      bloque_id, ejercicio_id, orden, descanso_planificado_seg,
      minutos_planificados
    )
    values (
      p_bloque_id,
      v_ejercicio.ejercicio_id,
      v_orden,
      v_ejercicio.descanso_seg,
      case when v_ejercicio.por_minutos then v_ejercicio.minutos end
    )
    returning id into v_nuevo;

    insert into series_planificadas (
      ejercicio_planificado_id, numero_serie,
      repeticiones_planificadas, peso_planificado, rir_planificado
    )
    select v_nuevo, ps.numero_serie, ps.repeticiones, ps.peso, ps.rir
    from pack_series ps
    where ps.pack_ejercicio_id = v_ejercicio.id
    order by ps.numero_serie;

    v_anadidos := v_anadidos + 1;
  end loop;

  if v_anadidos = 0 and v_omitidos = 0 then
    raise exception 'Ese pack no tiene ejercicios'
      using errcode = 'check_violation';
  end if;

  return jsonb_build_object(
    'ejercicios_anadidos', v_anadidos,
    'ejercicios_omitidos', v_omitidos
  );
end;
$$;

revoke execute on function aplicar_pack_a_bloque(uuid, uuid) from public;
grant execute on function aplicar_pack_a_bloque(uuid, uuid) to authenticated;
