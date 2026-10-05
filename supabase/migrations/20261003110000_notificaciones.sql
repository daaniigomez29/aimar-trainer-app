-- Fase 6 (1/2) · Preferencias de notificacion, suscripciones push y bitacora de
-- avisos (CU-22).
--
-- Tres piezas:
--   - `preferencias_notificacion`: si el cliente quiere push. El correo no se
--     puede desactivar, es el canal de respaldo universal (ver architecture.md).
--   - `suscripciones_push`: lo que el navegador entrega al suscribirse. Un mismo
--     cliente puede tener varias (movil y portatil, por ejemplo).
--   - `avisos_enviados`: que se envio, por que canal y con que resultado. CU-22
--     pide registrar el intento como **omitido** cuando el cliente tiene el push
--     desactivado, asi que "omitido" es un estado de pleno derecho, no un hueco.
--
-- Como en la fase 5, ninguna politica para `es_administrador()`.

create type tipo_aviso as enum ('sesion', 'control');
create type canal_aviso as enum ('correo', 'push');
create type estado_aviso as enum ('enviado', 'omitido', 'fallido');

-- ---------------------------------------------------------------------------
-- Preferencias
-- ---------------------------------------------------------------------------

-- Sin fila para un cliente = push desactivado. Es el valor por defecto correcto:
-- el push exige un permiso explicito del navegador que todavia no ha dado.
create table preferencias_notificacion (
  cliente_id uuid primary key references clientes(id) on delete cascade,
  push_activado boolean not null default false,
  actualizado_en timestamptz not null default now()
);

alter table preferencias_notificacion enable row level security;

grant select, insert, update on preferencias_notificacion to authenticated;
revoke truncate, trigger, references on table preferencias_notificacion
  from anon, authenticated;
-- La Edge Function las lee para decidir si manda el push o lo omite.
grant select on preferencias_notificacion to service_role;

create policy "el cliente gestiona sus preferencias"
  on preferencias_notificacion for all
  to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Suscripciones push
-- ---------------------------------------------------------------------------

create table suscripciones_push (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  -- La URL que el servicio de push del navegador asigna a este dispositivo.
  endpoint text not null,
  -- Claves de cifrado del navegador: sin ellas no se puede cifrar el payload.
  clave_p256dh text not null,
  clave_auth text not null,
  creada_en timestamptz not null default now(),

  constraint endpoint_no_vacio check (length(trim(endpoint)) > 0)
);

-- El endpoint identifica al dispositivo: si el navegador renueva la suscripcion
-- con el mismo endpoint, se actualiza la fila en vez de duplicarla.
create unique index suscripciones_push_endpoint_unico
  on suscripciones_push (endpoint);

alter table suscripciones_push enable row level security;

-- Con `delete`: revocar el permiso de notificaciones en el navegador tiene que
-- poder borrar la suscripcion, no solo desactivarla.
grant select, insert, update, delete on suscripciones_push to authenticated;
revoke truncate, trigger, references on table suscripciones_push
  from anon, authenticated;
-- `delete` para `service_role` porque el servicio de push responde 404 o 410
-- cuando una suscripcion ha caducado, y entonces hay que tirarla: si no, se
-- reintenta cada dia para siempre.
grant select, delete on suscripciones_push to service_role;

create policy "el cliente gestiona sus suscripciones"
  on suscripciones_push for all
  to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Bitacora de avisos
-- ---------------------------------------------------------------------------

create table avisos_enviados (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo tipo_aviso not null,
  canal canal_aviso not null,
  estado estado_aviso not null,
  -- La fecha a la que se refiere el aviso: la de la sesion que toca manana, o la
  -- del dia de control. No es la fecha de envio.
  fecha_referencia date not null,
  motivo text,
  creado_en timestamptz not null default now()
);

-- Un aviso por cliente, tipo, canal y fecha. Es lo que hace el envio idempotente:
-- si el job se ejecuta dos veces (reintento, redespliegue), el segundo no vuelve
-- a avisar.
create unique index avisos_cliente_tipo_canal_fecha_unico
  on avisos_enviados (cliente_id, tipo, canal, fecha_referencia);

alter table avisos_enviados enable row level security;

-- El cliente solo lee: esta bitacora la escribe la Edge Function.
grant select on avisos_enviados to authenticated;
revoke truncate, trigger, references on table avisos_enviados
  from anon, authenticated;
grant select, insert, update on avisos_enviados to service_role;

create policy "el cliente ve sus propios avisos"
  on avisos_enviados for select
  to authenticated
  using (cliente_id = auth.uid());
