-- Fase 6 (2/2) · Job diario que dispara los recordatorios (CU-22).
--
-- `pg_cron` programa, `pg_net` hace la peticion HTTP a la Edge Function. Las dos
-- extensiones vienen con Supabase, aqui solo se activan.
--
-- DONDE ESTAN LA URL Y EL SECRETO: en Vault, no en esta migracion. Cambian en
-- cada entorno (en local la funcion esta detras de Kong, en la nube en el dominio
-- del proyecto) y el secreto no debe vivir en el repositorio. `supabase/seed.sql`
-- los crea para local; en dev y produccion se crean una vez a mano:
--
--   select vault.create_secret('https://<proyecto>.supabase.co/functions/v1/enviar-recordatorios', 'url_enviar_recordatorios');
--   select vault.create_secret('<cadena larga y aleatoria>', 'secreto_cron');
--
-- y ese mismo secreto se da a la funcion con
-- `supabase secrets set SECRETO_CRON=<la misma cadena>`.

create extension if not exists pg_net;
create extension if not exists pg_cron;

-- `security definer`: solo el dueno de la base puede leer Vault, y el job no debe
-- exigir que quien lo programe tenga esos privilegios. No recibe ningun dato de
-- fuera, asi que no hay nada que inyectar.
create function enviar_recordatorios_programados() returns bigint
  language plpgsql
  security definer
  set search_path = public, extensions, pg_temp
as $$
declare
  v_url text;
  v_secreto text;
  v_peticion bigint;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'url_enviar_recordatorios';
  select decrypted_secret into v_secreto
  from vault.decrypted_secrets where name = 'secreto_cron';

  -- Sin configurar no se invoca nada, pero tampoco se rompe el job: queda el
  -- aviso en el log y manana se vuelve a intentar.
  if v_url is null or v_secreto is null then
    raise warning
      'Recordatorios no enviados: faltan los secretos url_enviar_recordatorios '
      'o secreto_cron en Vault.';
    return null;
  end if;

  select net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      -- La funcion comprueba esta cabecera contra su propio SECRETO_CRON. No se
      -- usa la service_role key: no hace falta meterla en la base de datos.
      'x-secreto-cron', v_secreto
    ),
    body := jsonb_build_object('origen', 'cron')
  ) into v_peticion;

  return v_peticion;
end;
$$;

revoke execute on function enviar_recordatorios_programados() from public;

-- A las 17:00 UTC. pg_cron programa en UTC, asi que en Espana son las 19:00 en
-- horario de verano y las 18:00 en invierno: por la tarde en ambos casos, que es
-- cuando tiene sentido avisar de la sesion de manana. El calculo de que dia es
-- "hoy" y "manana" en Europe/Madrid lo hace la funcion, no esta expresion.
select cron.schedule(
  'recordatorios-diarios',
  '0 17 * * *',
  $$select public.enviar_recordatorios_programados();$$
);
