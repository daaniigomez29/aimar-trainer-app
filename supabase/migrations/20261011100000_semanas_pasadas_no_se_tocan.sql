-- Regla de dominio: **lo pasado no se toca**.
--
-- El entrenador no crea, modifica, borra ni duplica un planning de una semana
-- que ya ha terminado. Se trabaja la semana en curso y las siguientes.
--
-- POR QUE EN TRIGGERS Y NO EN RLS: por la trampa de los `update` con RLS. Una
-- politica que no deja ver la fila no da error, deja la peticion en 0 filas y
-- PostgREST responde 2xx; la app lo traduciria a "eso ya no existe", que no
-- explica nada. Un trigger puede decir por que.
--
-- TRES EXENCIONES, y cada una por un motivo distinto:
--
-- 1. **Solo aplica al entrenador** (`es_entrenador()`). Es una regla sobre
--    quien planifica. Ademas, sin esto el seed no arrancaria: inserta a
--    proposito dos semanas archivadas del pasado, y corre como `postgres` sin
--    sesion.
-- 2. **El cliente sigue registrando** lo que hizo en una semana pasada que
--    siga activa: si entrena el domingo y lo apunta el lunes, tiene que poder.
--    Por eso se dejan pasar los cambios que solo tocan columnas de lo
--    realizado. Una politica RLS no puede mirar **que columnas** se tocan
--    (ya pasó con reordenar), asi que se comprueba a mano.
-- 3. **Archivar sigue permitido**: cambiar `estado` no cambia el plan, y una
--    semana se archiva justo cuando ya ha pasado. Ademas es lo que libera la
--    semana en el indice unico para poder rehacerla.

-- El lunes de la semana en curso, en la zona del entrenador. En UTC no vale:
-- entre las 00:00 y las 02:00 españolas del lunes, UTC todavia esta en la
-- semana anterior y la regla dejaria editar lo que ya es pasado (trampa 22).
create function lunes_de_esta_semana() returns date
  language sql
  stable
  set search_path = public, pg_temp
as $$
  select (
    (now() at time zone 'Europe/Madrid')::date
    - (extract(isodow from (now() at time zone 'Europe/Madrid'))::integer - 1)
  );
$$;

create function semana_pasada(p_fecha_inicio date) returns boolean
  language sql
  stable
  set search_path = public, pg_temp
as $$
  select p_fecha_inicio < lunes_de_esta_semana();
$$;

revoke execute on function lunes_de_esta_semana() from public;
revoke execute on function semana_pasada(date) from public;
grant execute on function lunes_de_esta_semana() to authenticated;
grant execute on function semana_pasada(date) to authenticated;

-- ---------------------------------------------------------------------------
-- El planning
-- ---------------------------------------------------------------------------
create function prohibir_planning_de_semana_pasada() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
begin
  if not es_entrenador() then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    -- Archivar y reactivar si se permiten: no cambian el plan, y una semana se
    -- archiva justo cuando ya ha pasado.
    if (new.cliente_id, new.fecha_inicio, new.nombre_objetivo)
       is not distinct from
       (old.cliente_id, old.fecha_inicio, old.nombre_objetivo)
    then
      return new;
    end if;

    -- Ni tocar una semana pasada, ni mover un planning hacia ella.
    if semana_pasada(old.fecha_inicio) or semana_pasada(new.fecha_inicio) then
      raise exception
        'Esa semana ya ha pasado: su planning no se puede modificar'
        using errcode = 'check_violation';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if semana_pasada(old.fecha_inicio) then
      raise exception
        'Esa semana ya ha pasado: su planning no se puede borrar'
        using errcode = 'check_violation';
    end if;
    return old;
  end if;

  if semana_pasada(new.fecha_inicio) then
    raise exception
      'Esa semana ya ha pasado: no se puede planificar'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger comprobar_semana_pasada_planning
  before insert or update or delete on plannings_semanales
  for each row execute function prohibir_planning_de_semana_pasada();

-- ---------------------------------------------------------------------------
-- Lo que cuelga del planning
-- ---------------------------------------------------------------------------
--
-- Una sola funcion para las cuatro tablas, que mira `TG_TABLE_NAME` para saber
-- como llegar al planning.
--
-- OJO con la forma: va con `if` anidados y no con un `and` en la misma
-- condicion, porque **el `and` de SQL no garantiza cortocircuito**. Un
-- `if tg_table_name = 'sesiones_entrenamiento' and new.planning_id ...` se
-- evalua entero para las otras tablas y revienta con 42703, "record new has no
-- field planning_id". Lo mismo con `coalesce(new, old)`: sobre registros
-- pierde el tipo y los accesos a campos fallan. Cada rama usa `new` u `old`
-- segun la operacion, y se escriben por separado.
create function prohibir_cambios_en_semana_pasada() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_fecha date;
  v_padre uuid;
begin
  if not es_entrenador() then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  -- Lo que el cliente registra no es "modificar el plan": se deja pasar aunque
  -- la semana haya terminado. Una politica RLS no puede mirar que columnas se
  -- tocan, asi que se comprueba aqui.
  if tg_op = 'UPDATE' then
    if tg_table_name = 'sesiones_entrenamiento' then
      if (new.planning_id, new.nombre, new.orden)
         is not distinct from (old.planning_id, old.nombre, old.orden)
      then
        return new;
      end if;
    elsif tg_table_name = 'ejercicios_planificados' then
      if (new.bloque_id, new.ejercicio_id, new.orden,
          new.descanso_planificado_seg, new.minutos_planificados)
         is not distinct from
         (old.bloque_id, old.ejercicio_id, old.orden,
          old.descanso_planificado_seg, old.minutos_planificados)
      then
        return new;
      end if;
    end if;
  end if;

  if tg_table_name = 'sesiones_entrenamiento' then
    if tg_op = 'DELETE' then
      v_padre := old.planning_id;
    else
      v_padre := new.planning_id;
    end if;
    select p.fecha_inicio into v_fecha
    from plannings_semanales p where p.id = v_padre;

  elsif tg_table_name = 'bloques_ejercicio' then
    if tg_op = 'DELETE' then
      v_padre := old.sesion_id;
    else
      v_padre := new.sesion_id;
    end if;
    select p.fecha_inicio into v_fecha
    from plannings_semanales p
    join sesiones_entrenamiento s on s.planning_id = p.id
    where s.id = v_padre;

  elsif tg_table_name = 'ejercicios_planificados' then
    if tg_op = 'DELETE' then
      v_padre := old.bloque_id;
    else
      v_padre := new.bloque_id;
    end if;
    select p.fecha_inicio into v_fecha
    from plannings_semanales p
    join sesiones_entrenamiento s on s.planning_id = p.id
    join bloques_ejercicio b on b.sesion_id = s.id
    where b.id = v_padre;

  else
    if tg_op = 'DELETE' then
      v_padre := old.ejercicio_planificado_id;
    else
      v_padre := new.ejercicio_planificado_id;
    end if;
    select p.fecha_inicio into v_fecha
    from plannings_semanales p
    join sesiones_entrenamiento s on s.planning_id = p.id
    join bloques_ejercicio b on b.sesion_id = s.id
    join ejercicios_planificados ep on ep.bloque_id = b.id
    where ep.id = v_padre;
  end if;

  -- Sin planning detras no hay nada que proteger: pasa, y que decidan las
  -- claves ajenas. Ocurre al borrar en cascada, donde el padre ya no esta.
  if v_fecha is not null and semana_pasada(v_fecha) then
    raise exception
      'Esa semana ya ha pasado: su planificación no se puede cambiar'
      using errcode = 'check_violation';
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

create trigger comprobar_semana_pasada_sesiones
  before insert or update or delete on sesiones_entrenamiento
  for each row execute function prohibir_cambios_en_semana_pasada();

create trigger comprobar_semana_pasada_bloques
  before insert or update or delete on bloques_ejercicio
  for each row execute function prohibir_cambios_en_semana_pasada();

create trigger comprobar_semana_pasada_ejercicios
  before insert or update or delete on ejercicios_planificados
  for each row execute function prohibir_cambios_en_semana_pasada();

create trigger comprobar_semana_pasada_series
  before insert or update or delete on series_planificadas
  for each row execute function prohibir_cambios_en_semana_pasada();

-- ---------------------------------------------------------------------------
-- Duplicar
-- ---------------------------------------------------------------------------
--
-- El trigger ya lo impediria, pero saltaria a mitad de copia y con un mensaje
-- sobre el planning. Mejor pararlo antes de escribir nada y decir lo que pasa.
-- Se puede copiar **desde** una semana pasada (es el historico que interesa
-- reutilizar); lo que no se puede es copiar **hacia** ella.
create or replace function duplicar_planning(
  p_origen uuid,
  p_fecha_inicio date
) returns jsonb
  language plpgsql
  security invoker
  set search_path = public, pg_temp
as $$
declare
  v_cliente uuid;
  v_objetivo text;
  v_nuevo uuid;
  v_sesion_nueva uuid;
  v_bloque_nuevo uuid;
  v_ejercicio_nuevo uuid;
  v_orden integer;
  v_omitidos integer := 0;
  v_sesion record;
  v_bloque record;
  v_ejercicio record;
begin
  if semana_pasada(p_fecha_inicio) then
    raise exception 'No se puede duplicar sobre una semana que ya ha pasado'
      using errcode = 'check_violation';
  end if;

  select cliente_id, nombre_objetivo into v_cliente, v_objetivo
  from plannings_semanales
  where id = p_origen;

  if v_cliente is null then
    raise exception 'Ese planning ya no existe'
      using errcode = 'no_data_found';
  end if;

  insert into plannings_semanales (cliente_id, fecha_inicio, nombre_objetivo)
  values (v_cliente, p_fecha_inicio, v_objetivo)
  returning id into v_nuevo;

  for v_sesion in
    select id, nombre, orden
    from sesiones_entrenamiento
    where planning_id = p_origen
    order by orden
  loop
    insert into sesiones_entrenamiento (planning_id, nombre, orden)
    values (v_nuevo, v_sesion.nombre, v_sesion.orden)
    returning id into v_sesion_nueva;

    for v_bloque in
      select id, tipo, orden, notas
      from bloques_ejercicio
      where sesion_id = v_sesion.id
      order by orden
    loop
      insert into bloques_ejercicio (sesion_id, tipo, orden, notas)
      values (v_sesion_nueva, v_bloque.tipo, v_bloque.orden, v_bloque.notas)
      returning id into v_bloque_nuevo;

      v_omitidos := v_omitidos + (
        select count(*)
        from ejercicios_planificados ep
        join ejercicios e on e.id = ep.ejercicio_id
        where ep.bloque_id = v_bloque.id and e.estado <> 'activo'
      );

      v_orden := 0;
      for v_ejercicio in
        select ep.id, ep.ejercicio_id, ep.descanso_planificado_seg,
               ep.minutos_planificados
        from ejercicios_planificados ep
        join ejercicios e on e.id = ep.ejercicio_id
        where ep.bloque_id = v_bloque.id and e.estado = 'activo'
        order by ep.orden
      loop
        v_orden := v_orden + 1;

        insert into ejercicios_planificados (
          bloque_id, ejercicio_id, orden,
          descanso_planificado_seg, minutos_planificados
        )
        values (
          v_bloque_nuevo, v_ejercicio.ejercicio_id, v_orden,
          v_ejercicio.descanso_planificado_seg, v_ejercicio.minutos_planificados
        )
        returning id into v_ejercicio_nuevo;

        insert into series_planificadas (
          ejercicio_planificado_id, numero_serie,
          repeticiones_planificadas, peso_planificado, rir_planificado
        )
        select
          v_ejercicio_nuevo, sp.numero_serie,
          sp.repeticiones_planificadas, sp.peso_planificado, sp.rir_planificado
        from series_planificadas sp
        where sp.ejercicio_planificado_id = v_ejercicio.id
        order by sp.numero_serie;
      end loop;
    end loop;
  end loop;

  return jsonb_build_object(
    'planning_id', v_nuevo,
    'ejercicios_omitidos', v_omitidos
  );
end;
$$;
