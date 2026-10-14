-- El peso de un ejercicio se cuenta "por lado".
--
-- QUE ES: una **etiqueta**, no una operacion. Un ejercicio marcado asi se le
-- presenta al cliente como "7,5 kg por lado" en lugar de "7,5 kg". El numero se
-- guarda tal cual se escribe y no se multiplica por dos: si se multiplicara, el
-- historico dejaria de ser comparable con todo lo registrado hasta hoy y las
-- graficas ensenarian un salto que nunca ocurrio.
--
-- POR QUE VIVE EN `ejercicios` Y NO EN `ejercicios_planificados`: es una
-- propiedad del ejercicio y de como se carga (mancuernas, polea unilateral,
-- barra con discos por lado), no de una semana concreta. Ponerlo aqui ademas
-- evita copiarlo en los tres sitios que crean ejercicios planificados
-- (`guardar_ejercicio_planificado`, `duplicar_planning` y `duplicar_sesion`),
-- que es una copia mas que olvidar.
--
-- LO QUE IMPLICA, Y SE ACEPTA (decision del 2026-10-14): la app no versiona los
-- ejercicios, asi que desmarcarlo cambia tambien **como se lee el historico**
-- de ese ejercicio. Es el mismo comportamiento que ya tienen el nombre, el tipo
-- o la clasificacion muscular —renombrar un ejercicio renombra todo su
-- historico—, con la diferencia de que aqui lo que cambia no es solo la
-- etiqueta sino como se interpreta un numero ya guardado. Se asume porque el
-- motivo realista para desmarcarlo es haberlo marcado por error, y en ese caso
-- propagarlo es justo lo correcto; la interfaz lo avisa al quitar la marca.

alter table ejercicios
  add column peso_por_lado boolean not null default false;

comment on column ejercicios.peso_por_lado is
  'Si el peso de este ejercicio se expresa por lado. Es solo presentacion: el '
  'peso se guarda tal cual, nunca se multiplica.';

-- ---------------------------------------------------------------------------
-- La vista de progreso lo arrastra, para que la grafica pueda decirlo
-- ---------------------------------------------------------------------------
--
-- Ya hacia join con `ejercicios`, asi que solo se anade la columna. Va **al
-- final** de la lista: `create or replace view` deja anadir columnas al final,
-- pero no reordenar ni renombrar las que ya existen.
create or replace view vista_progreso_ejercicios
with (security_invoker = on) as
select
  p.cliente_id,
  ep.ejercicio_id,
  e.nombre as ejercicio_nombre,
  e.tipo as ejercicio_tipo,
  s.id as sesion_id,
  s.fecha_realizada as fecha,
  sr.numero_serie,
  sr.repeticiones_realizadas,
  sr.peso_real,
  sr.rir_real,
  null::numeric as minutos_realizados,
  e.peso_por_lado
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
  ep.minutos_realizados,
  e.peso_por_lado
from ejercicios_planificados ep
join ejercicios e on e.id = ep.ejercicio_id
join bloques_ejercicio b on b.id = ep.bloque_id
join sesiones_entrenamiento s on s.id = b.sesion_id
join plannings_semanales p on p.id = s.planning_id
where ep.minutos_realizados is not null and s.fecha_realizada is not null;
