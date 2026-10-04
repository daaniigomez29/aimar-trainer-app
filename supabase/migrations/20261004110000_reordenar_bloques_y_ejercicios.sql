-- Reordenar bloques dentro de una sesion y ejercicios dentro de un bloque,
-- arrastrandolos en la pantalla de planificacion.
--
-- EL PROBLEMA: `orden` tiene indice unico, `(sesion_id, orden)` en bloques y
-- `(bloque_id, orden)` en ejercicios planificados, y esos indices se comprueban
-- fila a fila. Mover el bloque 3 al puesto 1 significa renumerar varias filas, y
-- cualquier orden en que se hagan los `update` pasa por un momento en que dos
-- filas comparten numero: el indice lo rechaza antes de llegar al estado final.
-- Desde la app serian ademas varias peticiones, y PostgREST abre una transaccion
-- por peticion: un fallo a mitad dejaria la sesion con dos bloques numerados
-- igual, que es justo lo que el indice existe para impedir.
--
-- LA SOLUCION: renumerar en dos fases dentro de una sola funcion, que se ejecuta
-- en la transaccion de quien la llama. Primero se apartan TODOS los ordenes a un
-- rango que no puede chocar con el definitivo (restando un millon, de forma
-- uniforme: siguen siendo distintos entre si), y despues se escriben los
-- definitivos. Ninguna de las dos fases colisiona, y si algo falla no se guarda
-- nada.
--
-- `security invoker` como en `guardar_ejercicio_planificado`: la funcion escribe
-- con los privilegios de quien llama, asi que RLS sigue decidiendo.
--
-- Y ADEMAS comprueban `es_entrenador()` explicitamente. Con los bloques bastaria
-- RLS, pero con los ejercicios planificados no: el cliente tiene una politica de
-- `update` sobre ellos para registrar sus minutos de cardio (CU-20), y esa
-- politica no puede limitar QUE columnas se tocan (es la "nota de seguridad
-- conocida" de `docs/sql-schema.md`). Sin esta comprobacion, estas funciones le
-- darian al cliente una forma comoda de reordenar el trabajo que le han puesto.
-- Reordenar es del entrenador: CU-11 y CU-12 son suyos.

-- Margen para apartar los ordenes. Mas grande que cualquier numero de bloques o
-- ejercicios que pueda tener una sesion real, por varios ordenes de magnitud.
create function reordenar_bloques(
  p_sesion_id uuid,
  -- Los bloques de la sesion, en el orden que deben quedar. Tienen que estar
  -- TODOS y una sola vez: esto renumera del 1 al N, no mueve uno suelto.
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
    raise exception 'Solo el entrenador reordena la planificacion'
      using errcode = 'insufficient_privilege';
  end if;

  if v_cuantos = 0 then
    raise exception 'No hay bloques que reordenar'
      using errcode = 'check_violation';
  end if;

  if v_cuantos <> (select count(distinct id) from unnest(p_ids) as t(id)) then
    raise exception 'La lista de bloques trae repetidos'
      using errcode = 'check_violation';
  end if;

  -- Que esten todos y que todos sean de esta sesion. Sin esto, una lista
  -- incompleta dejaria filas apartadas en el rango negativo.
  if v_cuantos <> (
    select count(*)
    from bloques_ejercicio
    where sesion_id = p_sesion_id and id = any(p_ids)
  ) or v_cuantos <> (
    select count(*) from bloques_ejercicio where sesion_id = p_sesion_id
  ) then
    raise exception 'La lista debe traer todos los bloques de la sesion'
      using errcode = 'check_violation';
  end if;

  update bloques_ejercicio
  set orden = orden - 1000000
  where sesion_id = p_sesion_id;

  -- Con RLS, un `update` prohibido no da error: no toca filas. Sin esta
  -- comprobacion, un cliente invocando la funcion se iria sin excepcion y sin
  -- haber reordenado nada.
  get diagnostics v_tocadas = row_count;
  if v_tocadas <> v_cuantos then
    raise exception 'No se ha podido reordenar: sin permiso sobre esos bloques'
      using errcode = 'insufficient_privilege';
  end if;

  update bloques_ejercicio b
  set orden = nuevo.posicion
  from (
    select id, ordinalidad::integer as posicion
    from unnest(p_ids) with ordinality as t(id, ordinalidad)
  ) as nuevo
  where b.id = nuevo.id and b.sesion_id = p_sesion_id;

  -- Red de seguridad: ninguna fila puede quedarse en el rango apartado.
  if exists (
    select 1 from bloques_ejercicio
    where sesion_id = p_sesion_id and orden < 0
  ) then
    raise exception 'No se ha podido reordenar: sin permiso sobre esos bloques'
      using errcode = 'insufficient_privilege';
  end if;
end;
$$;

create function reordenar_ejercicios_planificados(
  p_bloque_id uuid,
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
    raise exception 'Solo el entrenador reordena la planificacion'
      using errcode = 'insufficient_privilege';
  end if;

  if v_cuantos = 0 then
    raise exception 'No hay ejercicios que reordenar'
      using errcode = 'check_violation';
  end if;

  if v_cuantos <> (select count(distinct id) from unnest(p_ids) as t(id)) then
    raise exception 'La lista de ejercicios trae repetidos'
      using errcode = 'check_violation';
  end if;

  if v_cuantos <> (
    select count(*)
    from ejercicios_planificados
    where bloque_id = p_bloque_id and id = any(p_ids)
  ) or v_cuantos <> (
    select count(*) from ejercicios_planificados where bloque_id = p_bloque_id
  ) then
    raise exception 'La lista debe traer todos los ejercicios del bloque'
      using errcode = 'check_violation';
  end if;

  update ejercicios_planificados
  set orden = orden - 1000000
  where bloque_id = p_bloque_id;

  get diagnostics v_tocadas = row_count;
  if v_tocadas <> v_cuantos then
    raise exception
      'No se ha podido reordenar: sin permiso sobre esos ejercicios'
      using errcode = 'insufficient_privilege';
  end if;

  update ejercicios_planificados ep
  set orden = nuevo.posicion
  from (
    select id, ordinalidad::integer as posicion
    from unnest(p_ids) with ordinality as t(id, ordinalidad)
  ) as nuevo
  where ep.id = nuevo.id and ep.bloque_id = p_bloque_id;

  if exists (
    select 1 from ejercicios_planificados
    where bloque_id = p_bloque_id and orden < 0
  ) then
    raise exception
      'No se ha podido reordenar: sin permiso sobre esos ejercicios'
      using errcode = 'insufficient_privilege';
  end if;
end;
$$;

-- Igual que con `guardar_ejercicio_planificado`: el `grant` solo permite
-- invocarlas; quien puede escribir lo sigue decidiendo RLS dentro.
revoke execute on function reordenar_bloques(uuid, uuid[]) from public;
grant execute on function reordenar_bloques(uuid, uuid[]) to authenticated;

revoke execute on function reordenar_ejercicios_planificados(uuid, uuid[])
  from public;
grant execute on function reordenar_ejercicios_planificados(uuid, uuid[])
  to authenticated;
