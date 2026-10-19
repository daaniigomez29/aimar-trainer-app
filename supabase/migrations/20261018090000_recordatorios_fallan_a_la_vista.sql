-- Que un recordatorio sin configurar ponga el job en rojo, en vez de callarse.
--
-- QUE PASO (16-18/10/2026, trampa 36): al proyecto le faltaba el secreto
-- `url_enviar_recordatorios` en Vault. La funcion no lo encontraba, hacia
-- `raise warning`, devolvia `null` y **no llamaba a nadie**. Un warning no hace
-- fallar nada, asi que `cron.job_run_details` seguia diciendo `succeeded` todos
-- los dias y nadie se entero hasta que un cliente dijo que no le llegaban los
-- avisos. Una semana de silencio.
--
-- EL CAMBIO: `raise exception`. El job pasa a figurar como `failed` con el
-- motivo en `return_message`, que es donde se mira cuando algo no llega:
--
--   select status, return_message, start_time
--   from cron.job_run_details order by start_time desc limit 10;
--
-- Y el mensaje dice **cual** de los dos secretos falta, no "uno de los dos".
--
-- LO QUE ESTO NO CUBRE: si la llamada sale y la funcion responde 401 o 500, el
-- job ya ha terminado en verde. `net.http_post` encola la peticion y devuelve un
-- identificador al instante; la respuesta llega despues, a `net._http_response`,
-- y nadie la mira. Cubrir eso es otra cosa (que la funcion deje constancia de
-- cada envio y la app lo ensene), no un `raise`.
--
-- `55000` = object_not_in_prerequisite_state: el sistema existe pero no esta
-- listo para esto. No es un fallo de datos ni de permisos.

create or replace function enviar_recordatorios_programados() returns bigint
  language plpgsql
  security definer
  set search_path = public, extensions, pg_temp
as $$
declare
  v_url text;
  v_secreto text;
  v_peticion bigint;
  v_faltan text[] := '{}';
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'url_enviar_recordatorios';
  select decrypted_secret into v_secreto
  from vault.decrypted_secrets where name = 'secreto_cron';

  -- El cast a text no sobra: sin el, Postgres toma el literal por un array y
  -- revienta con "malformed array literal" en vez de anadir el elemento.
  if v_url is null then
    v_faltan := v_faltan || 'url_enviar_recordatorios'::text;
  end if;
  if v_secreto is null then
    v_faltan := v_faltan || 'secreto_cron'::text;
  end if;

  if array_length(v_faltan, 1) is not null then
    raise exception
      'Recordatorios no enviados: falta en Vault %',
      array_to_string(v_faltan, ' y ')
      using
        errcode = '55000',
        hint =
          'Se crean con vault.create_secret(valor, nombre): primero el valor. '
          'La URL es https://<ref>.supabase.co/functions/v1/enviar-recordatorios '
          'y secreto_cron tiene que coincidir con el SECRETO_CRON de la funcion.';
  end if;

  select net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-secreto-cron', v_secreto
    ),
    body := jsonb_build_object('origen', 'cron')
  ) into v_peticion;

  return v_peticion;
end;
$$;

-- `create or replace` conserva los privilegios, pero se repite por si esta
-- funcion se recrea alguna vez desde cero.
revoke execute on function enviar_recordatorios_programados() from public;
