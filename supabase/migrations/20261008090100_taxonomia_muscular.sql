-- Taxonomia muscular de la biblioteca: grupo muscular, musculo principal y
-- musculos secundarios, en lugar del `grupo_muscular text` libre.
--
-- Por que: con texto libre no existe jerarquia (en el seed convivian "Piernas"
-- e "Isquiotibiales", region y musculo al mismo nivel), asi que no se podia
-- filtrar por "Pierna -> Gluteo" ni saber que trabaja un ejercicio.
--
-- Los tres campos son **opcionales**: un cardio como la cinta de correr es de
-- Pierna sin musculo principal concreto, y un ejercicio de fortalecimiento
-- puede querer declarar solo la zona que se va a fortalecer.
--
-- El grupo se **deriva** del musculo principal cuando este existe (lo hace la
-- app, ver `Ejercicio.grupo`): la columna `grupo_muscular` solo guarda valor
-- cuando NO hay principal. El `check` de abajo impide que convivan, porque un
-- estado como "grupo: Pecho / principal: Cuadriceps" no lo detectaria nadie
-- hasta que el filtro mintiera.

create type grupo_muscular as enum (
  'pierna', 'pecho', 'espalda', 'hombro', 'brazo', 'core'
);

create type musculo as enum (
  -- Pierna
  'cuadriceps', 'isquiotibiales', 'gluteo', 'aductores', 'abductores', 'gemelo',
  -- Pecho
  'porcion_esterno_clavicular', 'porcion_esterno_costal',
  -- Espalda
  'dorsal_ancho', 'trapecio', 'romboides', 'lumbar',
  -- Hombro
  'deltoides_anterior', 'deltoides_lateral', 'deltoides_posterior',
  -- Brazo
  'biceps', 'triceps', 'antebrazo',
  -- Core
  'recto_abdominal', 'oblicuos', 'transverso'
);

-- Se **renombra** en vez de convertir el tipo de la columna: un `using` con
-- mapeo perderia en silencio los valores de texto que no esten contemplados.
-- Asi el texto original sigue consultable para reclasificar a mano lo que haga
-- falta, y se elimina en otra migracion cuando este todo limpio. Ninguna vista
-- ni funcion lee esta columna, asi que el renombrado no arrastra nada.
alter table ejercicios rename column grupo_muscular to grupo_muscular_antiguo;

alter table ejercicios
  add column grupo_muscular grupo_muscular,
  add column musculo_principal musculo,
  add column musculos_secundarios musculo[] not null default '{}';

-- Si hay musculo principal, el grupo se calcula a partir de el y no se guarda.
alter table ejercicios
  add constraint grupo_solo_sin_musculo_principal check (
    grupo_muscular is null or musculo_principal is null
  );

-- El principal no puede repetirse entre los secundarios.
alter table ejercicios
  add constraint principal_fuera_de_secundarios check (
    musculo_principal is null or
    not (musculo_principal = any (musculos_secundarios))
  );

-- Que no haya duplicados DENTRO de los secundarios se valida en el dominio
-- (`DatosEjercicio.validar`) y lo impide la interfaz, que es multiseleccion. No
-- se pone aqui porque la comprobacion necesita una subconsulta, que un `check`
-- no admite, y meterla en una funcion deja el `check` dependiendo de ella (con
-- los problemas de orden de `pg_dump` que eso arrastra).

-- ---------------------------------------------------------------------------
-- Reclasificacion de lo que ya habia
-- ---------------------------------------------------------------------------
--
-- Primero los valores que SI eran musculos, y solo despues el grupo de los que
-- eran regiones: al reves, el `check` rechazaria el estado intermedio.
update ejercicios set musculo_principal = case lower(grupo_muscular_antiguo)
    when 'cuadriceps' then 'cuadriceps'::musculo
    when 'cuádriceps' then 'cuadriceps'::musculo
    when 'isquiotibiales' then 'isquiotibiales'::musculo
    when 'isquios' then 'isquiotibiales'::musculo
    when 'gluteo' then 'gluteo'::musculo
    when 'glúteo' then 'gluteo'::musculo
    when 'gluteos' then 'gluteo'::musculo
    when 'glúteos' then 'gluteo'::musculo
    when 'aductores' then 'aductores'::musculo
    when 'abductores' then 'abductores'::musculo
    when 'gemelo' then 'gemelo'::musculo
    when 'gemelos' then 'gemelo'::musculo
    when 'dorsal' then 'dorsal_ancho'::musculo
    when 'dorsal ancho' then 'dorsal_ancho'::musculo
    when 'trapecio' then 'trapecio'::musculo
    when 'romboides' then 'romboides'::musculo
    when 'lumbar' then 'lumbar'::musculo
    when 'lumbares' then 'lumbar'::musculo
    when 'deltoides anterior' then 'deltoides_anterior'::musculo
    when 'deltoides lateral' then 'deltoides_lateral'::musculo
    when 'deltoides posterior' then 'deltoides_posterior'::musculo
    when 'biceps' then 'biceps'::musculo
    when 'bíceps' then 'biceps'::musculo
    when 'triceps' then 'triceps'::musculo
    when 'tríceps' then 'triceps'::musculo
    when 'antebrazo' then 'antebrazo'::musculo
    when 'oblicuos' then 'oblicuos'::musculo
    when 'transverso' then 'transverso'::musculo
    else null
  end
  where grupo_muscular_antiguo is not null;

update ejercicios set grupo_muscular = case lower(grupo_muscular_antiguo)
    when 'pierna' then 'pierna'::grupo_muscular
    when 'piernas' then 'pierna'::grupo_muscular
    when 'pecho' then 'pecho'::grupo_muscular
    when 'pectoral' then 'pecho'::grupo_muscular
    when 'espalda' then 'espalda'::grupo_muscular
    when 'hombro' then 'hombro'::grupo_muscular
    when 'hombros' then 'hombro'::grupo_muscular
    when 'brazo' then 'brazo'::grupo_muscular
    when 'brazos' then 'brazo'::grupo_muscular
    when 'core' then 'core'::grupo_muscular
    when 'abdomen' then 'core'::grupo_muscular
    when 'abdominales' then 'core'::grupo_muscular
    else null
  end
  where grupo_muscular_antiguo is not null
    and musculo_principal is null;

-- Lo que no mapee se queda sin clasificar a proposito, y la biblioteca lo
-- muestra en un chip "Sin clasificar" para que el entrenador lo complete desde
-- el formulario. Inventar el musculo principal de "Espalda" seria peor.
