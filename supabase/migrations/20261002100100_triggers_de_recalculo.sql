-- Fase 4 (cierre) · Triggers de recalculo de las columnas derivadas.
--
-- `ejercicios_planificados.estado_registro` y
-- `sesiones_entrenamiento.resultado_registrado` no los escribe nadie a mano: se
-- derivan de si el cliente ha registrado o no su resultado. Estos triggers los
-- mantienen.
--
-- Referencia: docs/sql-schema.md ("Triggers de recalculo automatico"). El doc
-- dejaba pendiente el caso de Cardio: el trigger `before update` que marca
-- `estado_registro` no puede recalcular la sesion, porque su propio cambio aun no
-- esta confirmado. Se resuelve aqui con un cuarto trigger `after update`.
--
-- POR QUE `security definer`: cuando el cliente registra una serie, el trigger
-- tiene que escribir en `sesiones_entrenamiento.resultado_registrado`, y las
-- politicas de esa tabla solo dan `update` al entrenador. Con `security invoker` el
-- registro del cliente fallaria. Estas funciones no aceptan datos del usuario: solo
-- recalculan un valor derivado de filas que ya existen, asi que ampliar privilegios
-- aqui no abre ninguna puerta. `search_path` fijado, como en el resto.

-- ---------------------------------------------------------------------------
-- Recalculo de la sesion
-- ---------------------------------------------------------------------------

-- Una sesion esta registrada cuando ninguno de sus ejercicios sigue pendiente.
-- Una sesion sin ejercicios no cuenta como registrada: no hay nada que registrar.
create function recalcular_resultado_sesion(p_sesion_id uuid) returns void
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
begin
  if p_sesion_id is null then
    return;
  end if;

  update sesiones_entrenamiento s
  set resultado_registrado = (
    exists (
      select 1
      from bloques_ejercicio b
      join ejercicios_planificados ep on ep.bloque_id = b.id
      where b.sesion_id = p_sesion_id
    )
    and not exists (
      select 1
      from bloques_ejercicio b
      join ejercicios_planificados ep on ep.bloque_id = b.id
      where b.sesion_id = p_sesion_id and ep.estado_registro = 'pendiente'
    )
  )
  where s.id = p_sesion_id;
end;
$$;

revoke execute on function recalcular_resultado_sesion(uuid) from public;

/* Sesion a la que pertenece un ejercicio planificado. */
create function sesion_de_ejercicio_planificado(p_ejercicio_planificado_id uuid)
  returns uuid
  language sql
  stable
  security definer
  set search_path = public, pg_temp
as $$
  select s.id
  from ejercicios_planificados ep
  join bloques_ejercicio b on b.id = ep.bloque_id
  join sesiones_entrenamiento s on s.id = b.sesion_id
  where ep.id = p_ejercicio_planificado_id;
$$;

revoke execute on function sesion_de_ejercicio_planificado(uuid) from public;

-- ---------------------------------------------------------------------------
-- Fuerza: el estado depende de que exista alguna serie realizada
-- ---------------------------------------------------------------------------

create function recalcular_estado_registro_por_series() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
declare
  v_ep_id uuid := coalesce(
    new.ejercicio_planificado_id,
    old.ejercicio_planificado_id
  );
begin
  update ejercicios_planificados
  set estado_registro = case
    when exists (
      select 1 from series_realizadas
      where ejercicio_planificado_id = v_ep_id
    ) then 'registrado'
    else 'pendiente'
  end
  where id = v_ep_id;

  -- El trigger `after update` de `ejercicios_planificados` se encarga de propagar
  -- el cambio a la sesion, asi que aqui no hace falta llamarla: si el `update` de
  -- arriba no cambio nada, tampoco hay nada que propagar.
  return null;
end;
$$;

create trigger recalcular_tras_serie_realizada
  after insert or update or delete on series_realizadas
  for each row execute function recalcular_estado_registro_por_series();

-- ---------------------------------------------------------------------------
-- Cardio: el estado depende de que haya minutos realizados
-- ---------------------------------------------------------------------------

create function recalcular_estado_registro_por_minutos() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
begin
  -- Solo cuando cambian los minutos realizados, y en los dos sentidos: anotarlos
  -- marca el ejercicio como registrado, y borrarlos lo devuelve a pendiente.
  if new.minutos_realizados is distinct from old.minutos_realizados then
    new.estado_registro := case
      when new.minutos_realizados is not null then 'registrado'
      else 'pendiente'
    end;
  end if;
  return new;
end;
$$;

create trigger recalcular_tras_minutos_cardio
  before update on ejercicios_planificados
  for each row execute function recalcular_estado_registro_por_minutos();

-- ---------------------------------------------------------------------------
-- El trigger que faltaba en el doc
-- ---------------------------------------------------------------------------

-- `recalcular_tras_minutos_cardio` es `before update`: cambia `estado_registro` en
-- la propia fila, pero en ese momento el cambio todavia no esta confirmado, asi que
-- no puede recalcular la sesion (la leeria con el valor viejo). Este `after update`
-- cierra el circulo: se dispara cuando `estado_registro` ya ha cambiado de verdad.
--
-- Cubre los dos caminos, Fuerza y Cardio, porque los dos acaban modificando
-- `estado_registro` de `ejercicios_planificados`.
create function propagar_estado_registro_a_sesion() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
begin
  perform recalcular_resultado_sesion(
    sesion_de_ejercicio_planificado(coalesce(new.id, old.id))
  );
  return null;
end;
$$;

-- OJO: NO se usa `after update OF estado_registro`. Postgres dispara `UPDATE OF
-- columna` segun las columnas **mencionadas en la sentencia**, no segun las que
-- cambian de verdad. Como el registro de Cardio es
-- `update ... set minutos_realizados = X` y es el trigger `before` quien toca
-- `estado_registro`, con `OF estado_registro` este trigger no se disparaba nunca y
-- la sesion no llegaba a marcarse como completa. El `when` si compara los valores
-- reales, y `new` ya refleja lo que dejo el trigger `before`.
create trigger propagar_estado_registro
  after update on ejercicios_planificados
  for each row
  when (old.estado_registro is distinct from new.estado_registro)
  execute function propagar_estado_registro_a_sesion();

-- Anadir o quitar un ejercicio de un bloque tambien cambia si la sesion esta
-- completa: una sesion "registrada" deja de estarlo si se le anade un ejercicio
-- nuevo, y puede pasar a estarlo si se quita el unico que faltaba.
create function propagar_alta_baja_de_ejercicio() returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
declare
  v_sesion_id uuid;
begin
  if tg_op = 'DELETE' then
    select sesion_id into v_sesion_id
    from bloques_ejercicio where id = old.bloque_id;
  else
    select sesion_id into v_sesion_id
    from bloques_ejercicio where id = new.bloque_id;
  end if;

  perform recalcular_resultado_sesion(v_sesion_id);
  return null;
end;
$$;

create trigger propagar_alta_baja_ejercicio
  after insert or delete on ejercicios_planificados
  for each row execute function propagar_alta_baja_de_ejercicio();

-- ---------------------------------------------------------------------------
-- Privilegios de `service_role` en las tablas de planificacion
-- ---------------------------------------------------------------------------

-- `service_role` salta RLS pero NO los privilegios de tabla (ver la nota de
-- docs/sql-schema.md). La Edge Function de recordatorios de CU-22 (fase 6) tendra
-- que leer las sesiones del dia siguiente y el cliente al que pertenecen, asi que
-- se le concede SELECT ya: es el mismo tropiezo que bloqueo `crear-cliente` en la
-- fase 3, y asi no se repite. Solo lectura: ninguna funcion necesita escribir aqui.
grant select on plannings_semanales to service_role;
grant select on sesiones_entrenamiento to service_role;
grant select on bloques_ejercicio to service_role;
grant select on ejercicios_planificados to service_role;
grant select on series_planificadas to service_role;
grant select on series_realizadas to service_role;
