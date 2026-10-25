begin;
select set_config('request.jwt.claims', json_build_object(
  'sub', (select id from perfiles where rol = 'entrenador'),
  'role', 'authenticated')::text, true);
set local role authenticated;

explain (analyze, buffers)
select * from vista_progreso_ejercicios
where cliente_id = (select id from clientes where nombre = 'Jesús García López')
  and ejercicio_id in (
    select ep.ejercicio_id
    from plannings_semanales p
    join sesiones_entrenamiento s on s.planning_id = p.id
    join bloques_ejercicio b on b.sesion_id = s.id
    join ejercicios_planificados ep on ep.bloque_id = b.id
    where p.cliente_id = (select id from clientes where nombre = 'Jesús García López')
      and p.fecha_inicio = '2026-10-26' and s.orden = 4)
  and fecha < '2026-10-26'
order by fecha desc
limit 400;

rollback;