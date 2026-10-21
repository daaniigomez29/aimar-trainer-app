-- Al quitar un ejercicio de un bloque, o un bloque de una sesion, los demas se
-- renumeran solos: sin huecos en `orden`.
--
-- QUE PASO (2026-10-21): Aimar quito el 6.o de 7 ejercicios de un bloque.
-- Borrar no renumeraba, asi que quedaron las posiciones 1-5 y 7. La app
-- proponia para el siguiente "cuantos hay + 1" = 7, que seguia ocupada, y el
-- indice unico de `(bloque_id, orden)` lo rechazaba: no se podia anadir nada.
-- La app ya se corrigio para proponer "la mas alta + 1", pero los huecos
-- seguian, y tenian dos consecuencias:
--   - En los bloques se ven: el cliente leeria "BLOQUE 1, BLOQUE 3".
--   - `aplicar_pack_a_bloque` calculaba la posicion con `count(*)`: aplicar un
--     pack a un bloque con huecos chocaba igual.
--
-- LO QUE HACE:
--   1. Dos funciones que renumeran del 1 al N, respetando el orden actual.
--   2. Un trigger por sentencia en cada tabla que, tras un borrado, renumera
--      los bloques o sesiones afectados.
--   3. Corrige una vez los huecos que ya existen.
--   4. `aplicar_pack_a_bloque` pasa a usar la posicion mas alta.
--
-- LO QUE NO TOCA: las sesiones ("Dia 1, Dia 2..."). Renumerarlas cambiaria el
-- numero de dias que el cliente quiza ya hizo y con el que los recuerda. Un
-- hueco ahi es raro y no rompe nada: el dia nuevo ya usa la posicion mas alta
-- (`PlanningSemanal.siguienteOrden`).

-- ---------------------------------------------------------------------------
-- Renumerar
-- ---------------------------------------------------------------------------
--
-- En dos fases, como `reordenar_bloques`: el indice unico se comprueba fila a
-- fila y renumerar en un solo `update` pasaria por dos filas con el mismo
-- numero. Aqui se aparta **sumando** un millon, no restando: asi la funcion
-- vale tambien si algun dia la tabla lleva `check (orden > 0)`, como las de
-- los packs.
--
-- Las llaman los triggers de abajo, como `security definer`. El trigger de "lo
-- pasado no se toca" sigue aplicando a lo que escriben, pero no estorba: en una
-- semana pasada tampoco se puede borrar.
--
-- Si no hay huecos no hace nada: quitar el ultimo, por ejemplo, no renumera ni
-- dispara los triggers de `update` de las filas hermanas.

create function renumerar_ejercicios_del_bloque(p_bloque_id uuid) returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from (
      select orden, row_number() over (order by orden, id) as posicion
      from ejercicios_planificados
      where bloque_id = p_bloque_id
    ) t
    where t.orden <> t.posicion
  ) then
    return;
  end if;

  update ejercicios_planificados
  set orden = orden + 1000000
  where bloque_id = p_bloque_id;

  update ejercicios_planificados ep
  set orden = nuevo.posicion
  from (
    select id, row_number() over (order by orden, id)::integer as posicion
    from ejercicios_planificados
    where bloque_id = p_bloque_id
  ) as nuevo
  where ep.id = nuevo.id;
end;
$$;

create function renumerar_bloques_de_la_sesion(p_sesion_id uuid) returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from (
      select orden, row_number() over (order by orden, id) as posicion
      from bloques_ejercicio
      where sesion_id = p_sesion_id
    ) t
    where t.orden <> t.posicion
  ) then
    return;
  end if;

  update bloques_ejercicio
  set orden = orden + 1000000
  where sesion_id = p_sesion_id;

  update bloques_ejercicio b
  set orden = nuevo.posicion
  from (
    select id, row_number() over (order by orden, id)::integer as posicion
    from bloques_ejercicio
    where sesion_id = p_sesion_id
  ) as nuevo
  where b.id = nuevo.id;
end;
$$;

-- Internas: las llaman los triggers y la correccion de abajo, no la app.
revoke execute on function renumerar_ejercicios_del_bloque(uuid) from public;
revoke execute on function renumerar_bloques_de_la_sesion(uuid) from public;

-- ---------------------------------------------------------------------------
-- Tras un borrado
-- ---------------------------------------------------------------------------
--
-- POR SENTENCIA, con la tabla de filas borradas: si se quitan varias a la vez,
-- cada bloque o sesion se renumera una sola vez.
--
-- EL `exists` DEL PADRE: al borrar un bloque, la cascada borra sus ejercicios
-- y este trigger salta tambien para ellos. Ese bloque ya no existe y no hay nada
-- que renumerar; intentarlo seria trabajo inutil sobre filas que se estan
-- borrando. Lo mismo con los bloques de una sesion o un planning borrados.
--
-- LOS TRIGGERS SON `security definer`, y las funciones de renumerar no se
-- pueden ejecutar desde la app (`revoke ... from public`, arriba). Un trigger
-- normal corre con el rol de quien borra, que entonces tampoco podria llamarlas.
-- Asi corren como el dueno: el borrado ya lo autorizo RLS antes de llegar aqui,
-- y renumerar sin huecos no da a nadie nada que no tuviera. Lo que no cambia es
-- `auth.uid()`, que sale del token de la sesion: el trigger de "lo pasado no se
-- toca" sigue viendo al entrenador.
--
-- Por que cerrarlas a la app: el cliente tiene politica de `update` sobre sus
-- ejercicios planificados (para registrar minutos de cardio), y abiertas le
-- darian una forma de tocar el orden de lo que le han planificado.

create function renumerar_tras_borrar_ejercicios() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
declare
  v_bloque uuid;
begin
  for v_bloque in
    select distinct borrados.bloque_id
    from borrados
    where exists (
      select 1 from bloques_ejercicio b where b.id = borrados.bloque_id
    )
  loop
    perform renumerar_ejercicios_del_bloque(v_bloque);
  end loop;
  return null;
end;
$$;

create trigger renumerar_tras_borrar_ejercicios
  after delete on ejercicios_planificados
  referencing old table as borrados
  for each statement
  execute function renumerar_tras_borrar_ejercicios();

create function renumerar_tras_borrar_bloques() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
declare
  v_sesion uuid;
begin
  for v_sesion in
    select distinct borrados.sesion_id
    from borrados
    where exists (
      select 1 from sesiones_entrenamiento s where s.id = borrados.sesion_id
    )
  loop
    perform renumerar_bloques_de_la_sesion(v_sesion);
  end loop;
  return null;
end;
$$;

create trigger renumerar_tras_borrar_bloques
  after delete on bloques_ejercicio
  referencing old table as borrados
  for each statement
  execute function renumerar_tras_borrar_bloques();

-- ---------------------------------------------------------------------------
-- Corregir los huecos que ya existen
-- ---------------------------------------------------------------------------
--
-- Una vez, al aplicar la migracion. Se ejecuta como el rol de las migraciones,
-- que no es el entrenador, asi que el trigger de "lo pasado no se toca" no la
-- frena y tambien quedan bien las semanas pasadas: es el mismo plan con la
-- numeracion corregida, no un cambio de plan.

do $$
declare
  v_id uuid;
begin
  for v_id in select id from bloques_ejercicio loop
    perform renumerar_ejercicios_del_bloque(v_id);
  end loop;
  for v_id in select id from sesiones_entrenamiento loop
    perform renumerar_bloques_de_la_sesion(v_id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- aplicar_pack_a_bloque: la posicion mas alta, no cuantos hay
-- ---------------------------------------------------------------------------
--
-- Igual que la de `20261019090000`, salvo el calculo de `v_orden`. Con el
-- renumerado ya no deberia haber huecos, pero contar filas para sacar una
-- posicion libre es fragil por definicion: si un dia vuelve a haber un hueco,
-- esto no debe ser lo que se rompa.

create or replace function aplicar_pack_a_bloque(
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

  select coalesce(max(orden), 0) into v_orden
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
