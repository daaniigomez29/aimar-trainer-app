-- Series o minutos, decidido por el MODO de planificacion y no por el tipo.
--
-- EL PROBLEMA que arregla: las dos comprobaciones de la exclusion
-- series/minutos preguntaban por valores concretos (`if v_tipo = 'cardio'` y
-- `if v_tipo = 'fuerza'`), sin rama por defecto. Al anadir 'fortalecimiento' un
-- ejercicio no entraba en ninguna de las dos, asi que habria podido tener
-- minutos Y series a la vez: justo la regla que estas funciones existen para
-- garantizar. Lo mismo al registrar, donde `p_minutos` se habria descartado en
-- silencio.
--
-- Ahora la pregunta es "¿este tipo se planifica con minutos?", con un `if/else`
-- que no deja hueco, y la respuesta vive en un unico sitio. Un cuarto tipo que
-- se anada al enum sin pasar por aqui **falla en voz alta** en lugar de colarse
-- por la rama de series.

create function planifica_con_minutos(p_tipo tipo_ejercicio) returns boolean
  language plpgsql
  immutable
  set search_path = public, pg_temp
as $$
begin
  case p_tipo
    when 'cardio' then return true;
    -- Fortalecimiento se planifica como Fuerza: series y repeticiones, con el
    -- peso y el RIR opcionales (peso corporal o goma elastica).
    when 'fuerza', 'fortalecimiento' then return false;
    else
      raise exception
        'El tipo de ejercicio % no tiene modo de planificacion definido', p_tipo;
  end case;
end;
$$;

-- No accede a ninguna tabla, asi que no revela nada; aun asi se sigue el mismo
-- criterio que con el resto de funciones y no se deja abierta a `public`.
revoke execute on function planifica_con_minutos(tipo_ejercicio) from public;
grant execute on function planifica_con_minutos(tipo_ejercicio) to authenticated;

-- ---------------------------------------------------------------------------
-- Al planificar
-- ---------------------------------------------------------------------------
--
-- Mismo nombre y misma firma, asi que el trigger
-- `comprobar_tipo_ejercicio_planificado` sigue apuntando aqui sin recrearlo.
create or replace function validar_tipo_ejercicio_planificado() returns trigger
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

  if planifica_con_minutos(v_tipo) then
    if new.minutos_planificados is null then
      raise exception 'Un ejercicio de % requiere minutos_planificados', v_tipo
        using errcode = 'check_violation';
    end if;
  else
    if new.minutos_planificados is not null or
       new.minutos_realizados is not null then
      raise exception 'Un ejercicio de % no admite minutos, usa series', v_tipo
        using errcode = 'check_violation';
    end if;
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Al registrar (CU-20)
-- ---------------------------------------------------------------------------
--
-- Firma identica a la de `20261003100000`, para reemplazarla en sitio y no
-- crear una sobrecarga. Los `grant` sobreviven al `create or replace`.
create or replace function registrar_resultado_ejercicio(
  p_ejercicio_planificado_id uuid,
  -- Solo para Cardio. `null` en Fuerza y Fortalecimiento.
  p_minutos numeric,
  -- Solo para los tipos que van por series:
  -- [{"numero_serie": 1, "repeticiones": 10, "peso": 60, "rir": 2}, ...]
  p_series jsonb
) returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_tipo tipo_ejercicio;
  v_con_minutos boolean;
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

  v_con_minutos := planifica_con_minutos(v_tipo);

  -- Series y minutos son excluyentes tambien al registrar, no solo al planificar.
  if not v_con_minutos and p_minutos is not null then
    raise exception 'Un ejercicio de % no registra minutos', v_tipo
      using errcode = 'check_violation';
  end if;

  if v_con_minutos and v_series > 0 then
    raise exception 'Un ejercicio de % no registra series', v_tipo
      using errcode = 'check_violation';
  end if;

  if v_con_minutos then
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
