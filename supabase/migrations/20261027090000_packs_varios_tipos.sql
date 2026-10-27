-- Un pack puede mezclar tipos de ejercicio, y sus etiquetas de tipo pasan a ser
-- varias (al menos una) y solo descriptivas.
--
-- POR QUE (2026-10-27, peticion de Aimar): quiere packs que mezclen, por
-- ejemplo, cardio y fuerza en un mismo conjunto. Hasta ahora el tipo del pack
-- era uno y mandaba sobre sus ejercicios: un trigger rechazaba los de otro tipo
-- (decision del 2026-10-19, `20261019090000`).
--
-- DECISION (Daniel): las etiquetas **no limitan** que ejercicios admite el
-- pack. Dicen de que va, para reconocerlo en la lista, pero un pack de
-- "Fuerza" puede llevar un cardio.
--
-- LO QUE SIGUE IGUAL: lo que va por minutos no lleva series y al reves. Solo
-- que ahora lo decide el tipo **del ejercicio**, no el del pack, igual que en
-- el planning (`validar_tipo_ejercicio_planificado`).
--
-- LO QUE NO HACE FALTA TOCAR: `aplicar_pack_a_bloque` ya decidia ejercicio a
-- ejercicio si copiar minutos (`planifica_con_minutos(e.tipo)`), y un bloque
-- del planning admite ejercicios de cualquier tipo.

-- ---------------------------------------------------------------------------
-- De `tipo` a `tipos`
-- ---------------------------------------------------------------------------
--
-- Una lista en la propia fila y no una tabla aparte: son como mucho tres
-- valores, se leen siempre junto al pack y no tienen datos propios.

alter table packs add column tipos tipo_ejercicio[];

update packs set tipos = array[tipo];

alter table packs
  alter column tipos set not null,
  add constraint al_menos_un_tipo check (cardinality(tipos) >= 1),
  drop column tipo;

-- Sin repetidos y siempre en el mismo orden (el del enum), lo mande quien lo
-- mande. Un `check` no puede hacerlo: no admite subconsultas.
create function normalizar_tipos_del_pack() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
begin
  new.tipos := array(select distinct t from unnest(new.tipos) as t order by t);
  return new;
end;
$$;

create trigger normalizar_tipos_del_pack
  before insert or update of tipos on packs
  for each row execute function normalizar_tipos_del_pack();

-- ---------------------------------------------------------------------------
-- Series o minutos, segun el ejercicio
-- ---------------------------------------------------------------------------

create or replace function validar_ejercicio_del_pack() returns trigger
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

  -- Ya no se compara con el pack: cualquier tipo vale. Los minutos, solo en lo
  -- que va por minutos; aqui pueden faltar.
  if not planifica_con_minutos(v_tipo) and new.minutos is not null then
    raise exception 'Un ejercicio de % no lleva minutos, lleva series', v_tipo
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create or replace function validar_serie_del_pack() returns trigger
  language plpgsql
  set search_path = public, pg_temp
as $$
declare
  v_tipo tipo_ejercicio;
begin
  select e.tipo into v_tipo
  from pack_ejercicios pe
  join ejercicios e on e.id = pe.ejercicio_id
  where pe.id = new.pack_ejercicio_id;

  if planifica_con_minutos(v_tipo) then
    raise exception 'Un ejercicio de % no lleva series, lleva minutos', v_tipo
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;
