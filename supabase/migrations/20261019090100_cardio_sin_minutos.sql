-- Un cardio planificado puede quedarse sin minutos, como una fuerza se queda
-- sin series.
--
-- POR QUE ESTABA ASI: la regla "un ejercicio planificado tiene que decir que
-- hacer" se implemento en dos sitios distintos por una limitacion tecnica, no
-- por una decision. Los minutos son una **columna de la propia fila**, asi que
-- un trigger `before insert` los puede exigir; las series son **filas de otra
-- tabla** que se insertan despues, asi que un trigger de fila siempre veria
-- cero. La mitad del cardio acabo en la base de datos y la de la fuerza solo en
-- Dart (`DatosEjercicioPlanificado.validar`), y de ahi la asimetria.
--
-- POR QUE SE RELAJA AHORA (decision del 2026-10-19): con los packs, el
-- entrenador puede preconfigurar los minutos **o no**, igual que las series. Si
-- la base los exige, aplicar un pack de cardio sin minutos obliga a inventar una
-- cifra (habia un `coalesce(..., 20)` en `aplicar_pack_a_bloque`), y el
-- entrenador se encuentra en el planning un dato que el no ha puesto. Mejor que
-- lo que falta se vea como lo que es: algo por rellenar.
--
-- Y la app ya lo sabia pintar: el editor tiene desde su primera version la rama
-- "Sin minutos planificados", para un estado que la base prohibia.
--
-- LO QUE NO CAMBIA: el formulario de CU-08 sigue pidiendo los minutos al anadir
-- un cardio a mano, porque ahi el entrenador esta diciendo que hacer ese dia.
-- Lo unico que puede dejarlos vacios es aplicar un pack que no los traia.

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

  -- Lo que se sigue prohibiendo: minutos en lo que va por series. Eso si es
  -- una contradiccion, no un hueco por rellenar.
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
