-- Fase 5 (4/4) · Registrar el resultado real de un ejercicio (CU-20).
--
-- EL PROBLEMA, el mismo de `guardar_ejercicio_planificado`: PostgREST abre una
-- transaccion por peticion, y registrar un ejercicio de Fuerza son varias series.
-- Dentro de una funcion todas caen en la misma transaccion: o se guardan todas, o
-- ninguna. Ademas da un unico sitio donde comprobar la exclusion Fuerza/Cardio
-- antes de escribir.
--
-- `security invoker`: RLS sigue aplicando dentro. Quien escribe de verdad lo
-- deciden las politicas de `series_realizadas` ("el cliente registra sus propias
-- series", solo sobre un planning activo suyo) y la de minutos de cardio en
-- `ejercicios_planificados`. Esta funcion no amplia permisos a nadie.
--
-- POR QUE `on conflict do update` Y NO `delete` + `insert`, al reves que en
-- `guardar_ejercicio_planificado`: a `series_realizadas` no se le concede `delete`
-- a proposito (lo que el cliente registro es historico; se corrige, no se borra).
-- Asi que aqui se actualiza en sitio la serie que ya existia, y se insertan las
-- nuevas. Consecuencia conocida: si el cliente registra 3 series y luego corrige a
-- 2, la tercera sigue ahi. Es el comportamiento que pide el diseno.
--
-- Registrar es incremental: el cliente puede confirmar una serie, dejarlo, y
-- seguir mas tarde. El trigger `recalcular_tras_serie_realizada` marca el ejercicio
-- como `registrado` en cuanto existe la primera.

create function registrar_resultado_ejercicio(
  p_ejercicio_planificado_id uuid,
  -- Solo para Cardio. `null` en Fuerza.
  p_minutos numeric,
  -- Solo para Fuerza:
  -- [{"numero_serie": 1, "repeticiones": 10, "peso": 60, "rir": 2}, ...]
  p_series jsonb
) returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_tipo tipo_ejercicio;
  v_series integer := coalesce(jsonb_array_length(p_series), 0);
begin
  -- El `select` ya pasa por RLS: si el ejercicio no es de quien llama, no lo ve y
  -- esto sale por "ya no existe". Cero filas con RLS activo no distingue "no
  -- existe" de "no puedes tocarlo", igual que en `guardar_ejercicio_planificado`.
  select e.tipo into v_tipo
  from ejercicios_planificados ep
  join ejercicios e on e.id = ep.ejercicio_id
  where ep.id = p_ejercicio_planificado_id;

  if v_tipo is null then
    raise exception 'Ese ejercicio planificado ya no existe'
      using errcode = 'no_data_found';
  end if;

  -- Fuerza y Cardio son mutuamente excluyentes tambien al registrar, no solo al
  -- planificar.
  if v_tipo = 'fuerza' and p_minutos is not null then
    raise exception 'Un ejercicio de Fuerza no registra minutos'
      using errcode = 'check_violation';
  end if;

  if v_tipo = 'cardio' and v_series > 0 then
    raise exception 'Un ejercicio de Cardio no registra series'
      using errcode = 'check_violation';
  end if;

  if v_tipo = 'cardio' then
    update ejercicios_planificados
    set minutos_realizados = p_minutos
    where id = p_ejercicio_planificado_id;

    -- RLS en un update no da error: deja la fila fuera y afecta a 0 filas.
    if not found then
      raise exception 'No puedes registrar el resultado de ese ejercicio'
        using errcode = 'insufficient_privilege';
    end if;

    return;
  end if;

  if v_series = 0 then
    return;
  end if;

  insert into series_realizadas (
    ejercicio_planificado_id, numero_serie,
    repeticiones_realizadas, peso_real, rir_real
  )
  select
    p_ejercicio_planificado_id,
    (serie ->> 'numero_serie')::integer,
    (serie ->> 'repeticiones')::integer,
    (serie ->> 'peso')::numeric,
    (serie ->> 'rir')::integer
  from jsonb_array_elements(p_series) as serie
  on conflict (ejercicio_planificado_id, numero_serie) do update set
    repeticiones_realizadas = excluded.repeticiones_realizadas,
    peso_real = excluded.peso_real,
    rir_real = excluded.rir_real,
    -- Corregir una serie actualiza tambien cuando se registro.
    fecha_hora_registro = now();
end;
$$;

-- Quien puede escribir lo sigue decidiendo RLS dentro; este `grant` solo permite
-- invocarla.
revoke execute on function registrar_resultado_ejercicio(uuid, numeric, jsonb)
  from public;
grant execute on function registrar_resultado_ejercicio(uuid, numeric, jsonb)
  to authenticated;
