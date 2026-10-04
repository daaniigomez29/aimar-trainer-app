-- La sesion deja de colgar de una fecha del calendario y pasa a numerarse
-- dentro de su planning: Dia 1, Dia 2, Dia 3.
--
-- POR QUE: el entrenador planifica "cuatro sesiones esta semana", no "una el
-- miercoles". Si el cliente no puede ir el miercoles y acaba yendo el jueves, la
-- sesion es la misma y no deberia quedar desplazada ni duplicada. Esto invierte
-- la regla que `AGENTS.md` fijaba en la fase 4 ("la planificacion se hace sobre
-- un calendario"), por decision explicita; el doc se actualiza con ella.
--
-- La fecha NO desaparece del todo: se guarda **cuando el cliente hizo la
-- sesion**, que es un dato distinto del que habia. Hoy no condiciona nada, solo
-- queda registrado y sirve de eje en la grafica de progreso (CU-21), donde antes
-- se usaba la fecha planificada.
--
-- El planning sigue siendo semanal: conserva su `fecha_inicio` y su indice de una
-- semana activa por cliente. Lo unico que cambia es como se identifican sus
-- sesiones.

-- ---------------------------------------------------------------------------
-- 1. Orden de la sesion dentro del planning
-- ---------------------------------------------------------------------------

alter table sesiones_entrenamiento add column orden integer;

-- Las sesiones que ya existen se numeran por la fecha que tenian, que es el
-- orden en el que el entrenador las penso.
update sesiones_entrenamiento s
set orden = n.numero
from (
  select id, row_number() over (
    partition by planning_id order by fecha
  ) as numero
  from sesiones_entrenamiento
) as n
where n.id = s.id;

alter table sesiones_entrenamiento alter column orden set not null;

alter table sesiones_entrenamiento add constraint orden_positivo
  check (orden > 0);

-- ---------------------------------------------------------------------------
-- 2. Fecha en la que se hizo
-- ---------------------------------------------------------------------------

-- Nullable: una sesion planificada y aun no hecha no tiene fecha. La rellena el
-- trigger de mas abajo en el primer registro del cliente.
alter table sesiones_entrenamiento add column fecha_realizada date;

-- La fecha vieja era la **planificada**, que ya no significa nada: se aprovecha
-- como fecha de realizacion solo donde la sesion esta registrada, para no perder
-- el historico que ya hubiera.
update sesiones_entrenamiento
set fecha_realizada = fecha
where resultado_registrado;

-- ---------------------------------------------------------------------------
-- 3. Fuera la fecha planificada y lo que la sostenia
-- ---------------------------------------------------------------------------

-- El trigger validaba que la fecha cayera dentro de la semana del planning. Sin
-- fecha planificada no hay nada que validar.
drop trigger comprobar_fecha_sesion on sesiones_entrenamiento;
drop function validar_fecha_sesion();

-- La vista de progreso usa la fecha de la sesion: hay que recrearla antes de
-- quitar la columna.
drop view vista_ejercicios_con_registro;
drop view vista_progreso_ejercicios;

drop index sesiones_planning_fecha_unico;
alter table sesiones_entrenamiento drop column fecha;

-- Dos sesiones no pueden ocupar el mismo numero dentro de un planning.
create unique index sesiones_planning_orden_unico
  on sesiones_entrenamiento (planning_id, orden);

-- ---------------------------------------------------------------------------
-- 4. La fecha de realizacion se rellena sola
-- ---------------------------------------------------------------------------

-- `recalcular_resultado_sesion` ya se invoca desde los triggers que miran las
-- series realizadas y los minutos de cardio, asi que es el sitio natural: en
-- cuanto hay **un** ejercicio registrado, la sesion tiene fecha.
--
-- `coalesce` para no pisarla despues: la fecha es la del primer registro, no la
-- del ultimo. Y en Europe/Madrid, no en UTC, por el mismo motivo que la Edge
-- Function de recordatorios.
create or replace function recalcular_resultado_sesion(p_sesion_id uuid)
  returns void
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
  ),
  fecha_realizada = case
    when exists (
      select 1
      from bloques_ejercicio b
      join ejercicios_planificados ep on ep.bloque_id = b.id
      where b.sesion_id = p_sesion_id
        and ep.estado_registro = 'registrado'
    )
    then coalesce(
      s.fecha_realizada,
      (now() at time zone 'Europe/Madrid')::date
    )
    -- Si el cliente deshace todo lo registrado, la sesion vuelve a no tener
    -- fecha: no se hizo.
    else null
  end
  where s.id = p_sesion_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Vistas de progreso sobre la fecha de realizacion
-- ---------------------------------------------------------------------------

create view vista_progreso_ejercicios
with (security_invoker = on) as
select
  p.cliente_id,
  ep.ejercicio_id,
  e.nombre as ejercicio_nombre,
  e.tipo as ejercicio_tipo,
  s.id as sesion_id,
  -- Antes era la fecha planificada; ahora, el dia en que se hizo de verdad.
  s.fecha_realizada as fecha,
  sr.numero_serie,
  sr.repeticiones_realizadas,
  sr.peso_real,
  sr.rir_real,
  null::numeric as minutos_realizados
from series_realizadas sr
join ejercicios_planificados ep on ep.id = sr.ejercicio_planificado_id
join ejercicios e on e.id = ep.ejercicio_id
join bloques_ejercicio b on b.id = ep.bloque_id
join sesiones_entrenamiento s on s.id = b.sesion_id
join plannings_semanales p on p.id = s.planning_id
where s.fecha_realizada is not null

union all

select
  p.cliente_id,
  ep.ejercicio_id,
  e.nombre,
  e.tipo,
  s.id,
  s.fecha_realizada,
  null::integer,
  null::integer,
  null::numeric,
  null::integer,
  ep.minutos_realizados
from ejercicios_planificados ep
join ejercicios e on e.id = ep.ejercicio_id
join bloques_ejercicio b on b.id = ep.bloque_id
join sesiones_entrenamiento s on s.id = b.sesion_id
join plannings_semanales p on p.id = s.planning_id
where ep.minutos_realizados is not null and s.fecha_realizada is not null;

grant select on vista_progreso_ejercicios to authenticated;

create view vista_ejercicios_con_registro
with (security_invoker = on) as
select distinct
  cliente_id,
  ejercicio_id,
  ejercicio_nombre,
  ejercicio_tipo
from vista_progreso_ejercicios;

grant select on vista_ejercicios_con_registro to authenticated;
