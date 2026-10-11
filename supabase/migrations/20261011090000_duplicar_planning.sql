-- Duplicar un planning semanal en otra semana (CU-05, variante).
--
-- EL PROBLEMA: un planning son cuatro niveles anidados (sesiones -> bloques ->
-- ejercicios planificados -> series planificadas), o sea decenas de `insert`
-- que tienen que ir todos o ninguno. PostgREST abre una transaccion por
-- peticion, asi que desde la app serian decenas de transacciones y una semana a
-- medias en cuanto una fallara. Por eso vive aqui, igual que
-- `guardar_ejercicio_planificado`.
--
-- QUE SE COPIA: **solo lo planificado**. Nada de lo que registro el cliente:
-- ni `series_realizadas`, ni `minutos_realizados`, ni `estado_registro`, ni
-- `fecha_realizada`, ni `resultado_registrado`. Si se copiara, el historico y
-- las graficas de CU-21 empezarian a contar entrenamientos que no existieron.
--
-- QUE NO SE COPIA ADEMAS: los ejercicios dados de baja. La regla de dominio
-- dice que un ejercicio eliminado no se anade a bloques nuevos, y duplicar es
-- anadirlo. Se omiten y la funcion **devuelve cuantos**, para que la app lo
-- diga: omitirlos en silencio dejaria bloques vacios sin explicacion.
--
-- `security invoker`: RLS sigue aplicando dentro. Quien puede duplicar lo
-- deciden las politicas "el entrenador gestiona ..." de cada tabla, no esta
-- funcion; un cliente que la invocara no veria el planning de origen y saldria
-- por "ya no existe".

create function duplicar_planning(
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
  -- El `select` ya pasa por RLS: si el planning no es visible para quien llama,
  -- esto sale por "ya no existe" sin distinguir de "no puedes verlo".
  select cliente_id, nombre_objetivo into v_cliente, v_objetivo
  from plannings_semanales
  where id = p_origen;

  if v_cliente is null then
    raise exception 'Ese planning ya no existe'
      using errcode = 'no_data_found';
  end if;

  -- El planning nuevo nace **activo**, aunque el origen estuviera archivado:
  -- es el plan de esa semana. Si la semana destino ya tiene uno activo, el
  -- indice `plannings_cliente_semana_unico` lo rechaza con un 23505; la app no
  -- deberia llegar aqui (el boton esta deshabilitado), pero la garantia no
  -- puede depender de la interfaz.
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

      -- Se renumera del 1 en adelante en vez de copiar el orden original: si se
      -- omite el ejercicio 2 de 3, copiar el orden dejaria 1 y 3, y la app
      -- calcula la siguiente posicion como "cuantos hay + 1", que ahi seria 3 y
      -- chocaria con el indice unico del bloque.
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

-- Quien puede duplicar lo sigue decidiendo RLS dentro; este `grant` solo
-- permite invocarla.
revoke execute on function duplicar_planning(uuid, date) from public;
grant execute on function duplicar_planning(uuid, date) to authenticated;
