-- Fase 5 (5/5) · Vistas de lectura para la consulta de progreso (CU-21).
--
-- POR QUE UNA VISTA: lo registrado cuelga de `series_realizadas` ->
-- `ejercicios_planificados` -> `bloques_ejercicio` -> `sesiones_entrenamiento` ->
-- `plannings_semanales`, y la fecha que le importa al cliente es la de la SESION,
-- no la de `fecha_hora_registro`. Pedir eso desde PostgREST obliga a encadenar
-- cuatro recursos incrustados con `!inner` y a filtrar por columnas anidadas;
-- aplanarlo aqui deja la consulta de la app en un `select` normal con sus filtros.
--
-- `security_invoker = on`: la vista se ejecuta con los permisos de quien consulta,
-- asi que **siguen aplicando las politicas RLS de las tablas de debajo**. El
-- cliente ve lo suyo, el entrenador lo de todos, y el administrador no ve nada
-- (no tiene politica en ninguna de esas tablas). Sin esta opcion la vista correria
-- con los permisos de su dueno y seria un agujero que puentearia RLS.

create view vista_progreso_ejercicios
with (security_invoker = on) as
-- Fuerza: una fila por serie realizada.
select
  p.cliente_id,
  ep.ejercicio_id,
  e.nombre as ejercicio_nombre,
  e.tipo as ejercicio_tipo,
  s.id as sesion_id,
  s.fecha,
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

union all

-- Cardio: una fila por ejercicio con minutos anotados.
select
  p.cliente_id,
  ep.ejercicio_id,
  e.nombre,
  e.tipo,
  s.id,
  s.fecha,
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
where ep.minutos_realizados is not null;

grant select on vista_progreso_ejercicios to authenticated;

-- Que ejercicios tienen algo registrado, para poder llenar el desplegable del
-- filtro sin traerse todas las series solo para sacar los nombres.
create view vista_ejercicios_con_registro
with (security_invoker = on) as
select distinct
  cliente_id,
  ejercicio_id,
  ejercicio_nombre,
  ejercicio_tipo
from vista_progreso_ejercicios;

grant select on vista_ejercicios_con_registro to authenticated;
