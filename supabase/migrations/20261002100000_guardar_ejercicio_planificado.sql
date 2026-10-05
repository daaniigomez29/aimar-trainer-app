-- Fase 4 (correccion) · Guardar un ejercicio planificado y sus series de forma
-- atomica.
--
-- EL PROBLEMA: PostgREST abre una transaccion por peticion HTTP. Guardar un
-- ejercicio de Fuerza son tres operaciones (upsert del ejercicio, borrar sus
-- series anteriores, insertar las nuevas), asi que desde el cliente eran tres
-- peticiones y tres transacciones independientes. Si fallaba la ultima, el
-- ejercicio se quedaba con las series a medias o sin ninguna, y no habia forma de
-- deshacerlo salvo compensando a mano.
--
-- LA SOLUCION: meter las tres operaciones dentro de una funcion. El cuerpo de una
-- funcion plpgsql se ejecuta en la transaccion de quien la llama, asi que una sola
-- llamada RPC = una sola transaccion: o se guarda todo, o no se guarda nada.
--
-- `security invoker` (el valor por defecto, explicito aqui para que se vea): la
-- funcion se ejecuta con los privilegios de quien llama, asi que **RLS sigue
-- aplicando** a cada insert, update y delete de dentro. Un cliente que la invocara
-- recibiria el mismo rechazo que escribiendo en la tabla directamente. Si fuera
-- `security definer` se convertiria en un agujero que puentearia las politicas.

create function guardar_ejercicio_planificado(
  -- `null` para crear; con valor, edita ese ejercicio.
  p_id uuid,
  p_bloque_id uuid,
  p_ejercicio_id uuid,
  p_orden integer,
  p_descanso_seg integer,
  p_minutos numeric,
  -- [{"numero_serie": 1, "repeticiones": 10, "peso": 60, "rir": 2}, ...]
  -- Vacio para Cardio.
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
    insert into ejercicios_planificados (
      bloque_id, ejercicio_id, orden,
      descanso_planificado_seg, minutos_planificados
    ) values (
      p_bloque_id, p_ejercicio_id, p_orden,
      p_descanso_seg, p_minutos
    )
    returning id into v_id;
  else
    update ejercicios_planificados set
      bloque_id = p_bloque_id,
      ejercicio_id = p_ejercicio_id,
      orden = p_orden,
      descanso_planificado_seg = p_descanso_seg,
      minutos_planificados = p_minutos
    where id = p_id
    returning id into v_id;

    -- Cero filas con RLS activo no distingue "no existe" de "no puedes tocarla".
    if v_id is null then
      raise exception 'Ese ejercicio planificado ya no existe'
        using errcode = 'no_data_found';
    end if;

    -- Se reemplazan siempre, incluso por una lista vacia: al pasar de Fuerza a
    -- Cardio hay que dejar el ejercicio sin series.
    delete from series_planificadas where ejercicio_planificado_id = v_id;
  end if;

  if p_series is not null and jsonb_array_length(p_series) > 0 then
    insert into series_planificadas (
      ejercicio_planificado_id, numero_serie,
      repeticiones_planificadas, peso_planificado, rir_planificado
    )
    select
      v_id,
      (serie ->> 'numero_serie')::integer,
      (serie ->> 'repeticiones')::integer,
      (serie ->> 'peso')::numeric,
      (serie ->> 'rir')::integer
    from jsonb_array_elements(p_series) as serie;
  end if;

  return v_id;
end;
$$;

-- Quien puede escribir de verdad lo sigue decidiendo RLS dentro de la funcion;
-- este `grant` solo permite invocarla.
revoke execute on function guardar_ejercicio_planificado(
  uuid, uuid, uuid, integer, integer, numeric, jsonb
) from public;
grant execute on function guardar_ejercicio_planificado(
  uuid, uuid, uuid, integer, integer, numeric, jsonb
) to authenticated;
