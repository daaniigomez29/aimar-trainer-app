-- Datos de demostración para trastear con la app sin tener que escribirlo todo a
-- mano: biblioteca de ejercicios, un cliente con tres semanas de planificación y
-- resultados ya registrados, sus medidas y sus check-in.
--
-- SOLO LOCAL, igual que `seed.sql`: lo aplica `supabase db reset` porque está
-- listado en `[db.seed] sql_paths` de `config.toml`. Para no cargarlo, basta con
-- quitarlo de esa lista.
--
-- POR QUÉ UN CLIENTE DISTINTO de `cliente@local.test`: `scripts/probar_local.sh`
-- usa ese cliente y crea para él un planning activo de la semana en curso. Si el
-- seed le dejara uno, el índice de "un planning activo por cliente y semana"
-- haría fallar ese bloque entero con un 409 antes de empezar. El cliente de
-- demostración es aparte y el script ni lo mira.
--
-- Cuenta: demo@local.test · contraseña aimar-local-2026 (la misma que el resto).

-- ---------------------------------------------------------------------------
-- Biblioteca de ejercicios
-- ---------------------------------------------------------------------------
--
-- `on conflict do nothing` por el índice de nombre único entre activos: así este
-- archivo se puede volver a aplicar sobre una base que ya los tenga.
--
-- El vídeo de ejemplo es un corto libre de YouTube, puesto solo para probar que
-- el reproductor incrustado funciona. Sustitúyelo por los vídeos reales de Aimar
-- cuando los haya.
insert into ejercicios (
  nombre, descripcion, tipo, grupo_muscular, equipamiento, video_ejemplo_url
) values
  ('Press de banca', 'Tumbado en banco plano, baja la barra al pecho con los codos a unos 45 grados y empuja hasta extender.', 'fuerza', 'Pecho', 'Barra', 'https://www.youtube.com/watch?v=aqz-KE-bpKQ'),
  ('Press inclinado con mancuernas', 'Banco a 30 grados. Baja las mancuernas a la altura del pecho y sube sin chocarlas arriba.', 'fuerza', 'Pecho', 'Mancuernas', null),
  ('Fondos en paralelas', 'Cuerpo ligeramente inclinado hacia delante. Baja hasta que el codo haga 90 grados.', 'fuerza', 'Pecho', 'Paralelas', null),
  ('Dominadas', 'Agarre prono algo más ancho que los hombros. Sube hasta pasar la barbilla sin balancearte.', 'fuerza', 'Espalda', 'Barra fija', null),
  ('Remo con barra', 'Tronco inclinado unos 45 grados, espalda neutra. Lleva la barra al abdomen.', 'fuerza', 'Espalda', 'Barra', null),
  ('Jalón al pecho', 'Sentado, tira de la barra hacia la parte alta del pecho juntando las escápulas.', 'fuerza', 'Espalda', 'Polea', null),
  ('Sentadilla trasera', 'Barra en el trapecio. Baja controlando hasta romper la paralela y sube empujando con el talón.', 'fuerza', 'Piernas', 'Barra', null),
  ('Peso muerto rumano', 'Rodillas poco flexionadas, lleva la cadera atrás y baja la barra pegada a la pierna.', 'fuerza', 'Isquiotibiales', 'Barra', null),
  ('Prensa de piernas', 'Pies a la anchura de los hombros. No bloquees la rodilla arriba.', 'fuerza', 'Piernas', 'Máquina', null),
  ('Press militar', 'De pie, barra a la altura de la clavícula. Empuja arriba sin arquear la zona lumbar.', 'fuerza', 'Hombros', 'Barra', null),
  ('Elevaciones laterales', 'Sube los brazos hasta la altura del hombro, con el codo algo flexionado.', 'fuerza', 'Hombros', 'Mancuernas', null),
  ('Curl con barra Z', 'Codos pegados al cuerpo, sube sin balancear el tronco.', 'fuerza', 'Bíceps', 'Barra Z', null),
  ('Cinta de correr', 'Carrera continua a ritmo suave, por debajo del umbral de conversación.', 'cardio', 'Piernas', 'Cinta', null),
  ('Bicicleta estática', 'Pedaleo constante, resistencia media.', 'cardio', 'Piernas', 'Bicicleta', null),
  ('Remo ergómetro', 'Secuencia piernas, tronco, brazos. Vuelta en orden inverso.', 'cardio', 'Espalda', 'Remo', null)
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Auxiliares
-- ---------------------------------------------------------------------------
--
-- La función de crear usuarios se vuelve a declarar aquí: `pg_temp` es el
-- esquema temporal de la sesión, y no hay garantía de que la CLI ejecute todos
-- los archivos de seed en la misma. `create or replace` la deja igual si ya
-- estaba.
create or replace function pg_temp.crear_usuario_de_prueba(
  p_correo text,
  p_contrasena text,
  p_rol rol_usuario
) returns uuid
  language plpgsql as $$
declare
  v_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change, email_change_token_new,
    email_change_token_current, phone_change, phone_change_token,
    reauthentication_token
  ) values (
    v_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', p_correo, crypt(p_contrasena, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    '', '', '', '', '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_id, v_id::text, 'email',
    jsonb_build_object('sub', v_id::text, 'email', p_correo, 'email_verified', true),
    now(), now(), now()
  );

  insert into perfiles (id, rol) values (v_id, p_rol);
  return v_id;
end;
$$;

-- Un ejercicio de Fuerza con sus series planificadas, todas iguales. Devuelve el
-- id para poder registrarle después lo que el cliente hizo.
create or replace function pg_temp.planificar_fuerza(
  p_bloque uuid,
  p_ejercicio text,
  p_orden integer,
  p_series integer,
  p_reps integer,
  p_peso numeric,
  p_rir integer,
  p_descanso integer default 90
) returns uuid
  language plpgsql as $$
declare
  v_id uuid;
begin
  insert into ejercicios_planificados (
    bloque_id, ejercicio_id, orden, descanso_planificado_seg
  )
  select p_bloque, e.id, p_orden, p_descanso
  from ejercicios e where e.nombre = p_ejercicio
  returning id into v_id;

  insert into series_planificadas (
    ejercicio_planificado_id, numero_serie,
    repeticiones_planificadas, peso_planificado, rir_planificado
  )
  select v_id, n, p_reps, p_peso, p_rir
  from generate_series(1, p_series) as n;

  return v_id;
end;
$$;

-- El Cardio no lleva series: define minutos y ya está (regla de dominio).
create or replace function pg_temp.planificar_cardio(
  p_bloque uuid,
  p_ejercicio text,
  p_orden integer,
  p_minutos numeric
) returns uuid
  language plpgsql as $$
declare
  v_id uuid;
begin
  insert into ejercicios_planificados (
    bloque_id, ejercicio_id, orden, minutos_planificados
  )
  select p_bloque, e.id, p_orden, p_minutos
  from ejercicios e where e.nombre = p_ejercicio
  returning id into v_id;
  return v_id;
end;
$$;

-- Lo que el cliente hizo: no tiene por qué coincidir con lo planificado, y aquí
-- no coincide a propósito (la última serie siempre se queda corta de
-- repeticiones, que es lo que pasa de verdad).
create or replace function pg_temp.registrar_fuerza(
  p_ejercicio_planificado uuid,
  p_series integer,
  p_reps integer,
  p_peso numeric,
  p_rir integer
) returns void
  language plpgsql as $$
begin
  insert into series_realizadas (
    ejercicio_planificado_id, numero_serie,
    repeticiones_realizadas, peso_real, rir_real
  )
  select
    p_ejercicio_planificado,
    n,
    -- La última cae un par de repeticiones: llega la fatiga.
    case when n = p_series then greatest(p_reps - 2, 1) else p_reps end,
    p_peso,
    case when n = p_series then greatest(p_rir - 1, 0) else p_rir end
  from generate_series(1, p_series) as n;
end;
$$;

-- Una sesión entera con sus tres bloques. Devuelve el id de la sesión.
create or replace function pg_temp.crear_sesion(
  p_planning uuid,
  p_orden integer,
  p_nombre text
) returns uuid
  language plpgsql as $$
declare
  v_id uuid;
begin
  insert into sesiones_entrenamiento (planning_id, orden, nombre)
  values (p_planning, p_orden, p_nombre)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function pg_temp.crear_bloque(
  p_sesion uuid,
  p_tipo tipo_bloque,
  p_orden integer,
  p_notas text default null
) returns uuid
  language plpgsql as $$
declare
  v_id uuid;
begin
  insert into bloques_ejercicio (sesion_id, tipo, orden, notas)
  values (p_sesion, p_tipo, p_orden, p_notas)
  returning id into v_id;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Cliente de demostración y sus tres semanas
-- ---------------------------------------------------------------------------
do $$
declare
  v_cliente uuid;
  v_lunes date := date_trunc('week', current_date)::date;
  v_plan uuid;
  v_sesion uuid;
  v_bloque uuid;
  v_ep uuid;
  v_semana integer;
  -- La carga sube una semana sobre otra: es lo que el entrenador quiere ver de
  -- un vistazo cuando planifica la siguiente.
  v_peso_banca numeric;
  v_peso_sentadilla numeric;
begin
  v_cliente := pg_temp.crear_usuario_de_prueba(
    'demo@local.test', 'aimar-local-2026', 'cliente'
  );

  insert into clientes (
    id, nombre, correo, fecha_nacimiento, altura_cm, peso_inicial_kg,
    objetivos, dia_control_preferido
  ) values (
    v_cliente, 'Ana Demo', 'demo@local.test',
    '1993-07-21', 167.00, 62.00,
    'Subir fuerza en press de banca y sentadilla sin ganar peso corporal',
    'miercoles'
  );

  -- v_semana: 2 = hace dos semanas, 1 = la pasada, 0 = la que se está
  -- planificando ahora. Las dos primeras quedan archivadas y con resultados; la
  -- de esta semana se deja planificada y sin registrar, que es el estado en el
  -- que el entrenador se la encuentra.
  for v_semana in reverse 2 .. 0 loop
    v_peso_banca := 42.5 + (2 - v_semana) * 2.5;
    v_peso_sentadilla := 60 + (2 - v_semana) * 5;

    insert into plannings_semanales (
      cliente_id, fecha_inicio, nombre_objetivo, estado
    ) values (
      v_cliente,
      v_lunes - v_semana * 7,
      case v_semana
        when 2 then 'Adaptación'
        when 1 then 'Subida de carga'
        else 'Semana en curso'
      end,
      (case when v_semana = 0 then 'activo' else 'archivado' end)::estado_planning
    ) returning id into v_plan;

    -- ---- Día 1: empuje ----
    v_sesion := pg_temp.crear_sesion(v_plan, 1, 'Empuje');
    v_bloque := pg_temp.crear_bloque(
      v_sesion, 'calentamiento', 1, 'Movilidad de hombro y dos series ligeras.'
    );
    v_ep := pg_temp.planificar_cardio(v_bloque, 'Bicicleta estática', 1, 8);
    if v_semana > 0 then
      update ejercicios_planificados set minutos_realizados = 8 where id = v_ep;
    end if;

    v_bloque := pg_temp.crear_bloque(v_sesion, 'fuerza', 2);
    v_ep := pg_temp.planificar_fuerza(
      v_bloque, 'Press de banca', 1, 4, 8, v_peso_banca, 2, 120
    );
    if v_semana > 0 then
      perform pg_temp.registrar_fuerza(v_ep, 4, 8, v_peso_banca, 2);
    end if;

    v_ep := pg_temp.planificar_fuerza(
      v_bloque, 'Press inclinado con mancuernas', 2, 3, 10, 14, 2
    );
    if v_semana > 0 then
      perform pg_temp.registrar_fuerza(v_ep, 3, 10, 14, 2);
    end if;

    -- Fondos solo en la primera semana y en la actual: así en la pantalla de
    -- planificación se ve el caso "esta semana no lo hizo", que cae al último
    -- registro y lo avisa con la fecha.
    if v_semana <> 1 then
      v_ep := pg_temp.planificar_fuerza(
        v_bloque, 'Fondos en paralelas', 3, 3, 8, null, 2
      );
      if v_semana = 2 then
        perform pg_temp.registrar_fuerza(v_ep, 3, 8, null, 2);
      end if;
    end if;

    -- ---- Día 2: tirón ----
    v_sesion := pg_temp.crear_sesion(v_plan, 2, 'Tirón');
    v_bloque := pg_temp.crear_bloque(v_sesion, 'fuerza', 1);
    v_ep := pg_temp.planificar_fuerza(v_bloque, 'Dominadas', 1, 4, 6, null, 1);
    if v_semana > 0 then
      perform pg_temp.registrar_fuerza(v_ep, 4, 6, null, 1);
    end if;

    v_ep := pg_temp.planificar_fuerza(
      v_bloque, 'Remo con barra', 2, 4, 10, 35 + (2 - v_semana) * 2.5, 2
    );
    if v_semana > 0 then
      perform pg_temp.registrar_fuerza(
        v_ep, 4, 10, 35 + (2 - v_semana) * 2.5, 2
      );
    end if;

    v_ep := pg_temp.planificar_fuerza(v_bloque, 'Curl con barra Z', 3, 3, 12, 20, 1, 60);
    if v_semana > 0 then
      perform pg_temp.registrar_fuerza(v_ep, 3, 12, 20, 1);
    end if;

    -- ---- Día 3: pierna ----
    v_sesion := pg_temp.crear_sesion(v_plan, 3, 'Pierna');
    v_bloque := pg_temp.crear_bloque(
      v_sesion, 'fuerza', 1, 'Sentadilla pesada, el resto a sensaciones.'
    );
    v_ep := pg_temp.planificar_fuerza(
      v_bloque, 'Sentadilla trasera', 1, 5, 5, v_peso_sentadilla, 2, 180
    );
    -- La semana pasada dejó esta sesión a medias: sirve para ver una sesión con
    -- parte registrada y parte pendiente.
    if v_semana = 2 then
      perform pg_temp.registrar_fuerza(v_ep, 5, 5, v_peso_sentadilla, 2);
    elsif v_semana = 1 then
      perform pg_temp.registrar_fuerza(v_ep, 3, 5, v_peso_sentadilla, 2);
    end if;

    v_ep := pg_temp.planificar_fuerza(
      v_bloque, 'Peso muerto rumano', 2, 3, 10, 40, 2
    );
    if v_semana = 2 then
      perform pg_temp.registrar_fuerza(v_ep, 3, 10, 40, 2);
    end if;

    v_bloque := pg_temp.crear_bloque(v_sesion, 'cardio', 2);
    v_ep := pg_temp.planificar_cardio(v_bloque, 'Cinta de correr', 1, 20);
    if v_semana = 2 then
      update ejercicios_planificados set minutos_realizados = 22 where id = v_ep;
    end if;
  end loop;

  -- Las sesiones toman fecha al registrarse, y el trigger pone la de hoy. Aquí
  -- se corrigen a los días en que se hicieron de verdad, que es lo que la app
  -- enseña ("Hecha el 23/09") y el eje de la gráfica de progreso.
  update sesiones_entrenamiento s
  set fecha_realizada = p.fecha_inicio + (s.orden - 1) * 2
  from plannings_semanales p
  where p.id = s.planning_id
    and p.cliente_id = v_cliente
    and s.fecha_realizada is not null;

  -- ---- Medidas y check-in, para que el progreso del cliente no salga vacío ----
  insert into registros_medidas (
    cliente_id, fecha, peso_kg, cintura_cm, pecho_cm, cadera_cm, brazos_cm
  ) values
    (v_cliente, v_lunes - 14, 62.0, 71.0, 88.0, 94.0, 28.0),
    (v_cliente, v_lunes - 7, 61.6, 70.5, 88.5, 94.0, 28.2),
    (v_cliente, v_lunes, 61.4, 70.0, 89.0, 93.5, 28.5);

  insert into checkins_recuperacion (
    cliente_id, fecha, horas_sueno, estres, agujetas, fatiga, notas
  ) values
    (v_cliente, v_lunes - 14, 7.5, 4, 6, 5, 'Semana tranquila.'),
    (v_cliente, v_lunes - 7, 6.5, 6, 7, 6, 'Dormí poco entre semana.'),
    (v_cliente, v_lunes, 8.0, 3, 4, 3, null);

  insert into preferencias_notificacion (cliente_id, push_activado)
  values (v_cliente, true)
  on conflict do nothing;
end;
$$;
