Bitácora del proyecto

Registro cronológico de funcionalidades añadidas, correcciones y hallazgos durante el desarrollo. El agente añade una entrada aquí al terminar una tarea con cambios significativos, siguiendo el formato definido en AGENTS.md (sección "Bitácora de trabajo"). Las entradas más recientes van al final.

### 2026-09-30

Primera entrada de la bitácora: cubre la fase 1 completa (esqueleto, esquema
inicial y autenticación), empezada el día anterior.

**Hecho:**
- Estructura `lib/` feature-first: `core/{configuracion,enrutado,errores,plataforma,presentacion,supabase}`
  y `features/<feature>/{data,domain,application,presentation}`. Las cinco
  features de fases posteriores quedan con `.gitkeep` por capa.
- `Result<T>` (`Success`/`Failure`) y jerarquía sellada `ErrorApp` con mensajes
  en español ya redactados, en `core/errores/`.
- Migraciones iniciales en `supabase/migrations/`: `perfiles` + `es_entrenador()`
  / `es_administrador()`, `clientes` y `ejercicios`, con RLS y `GRANT` explícitos.
- Feature `autenticacion` (CU-01 y CU-24): interfaz `AutenticacionRepositorio` en
  `domain/`, implementación Supabase en `data/` que traduce toda excepción de
  Supabase a `ErrorApp`, tres Notifiers en `application/` y pantallas de login,
  solicitud de recuperación y restablecimiento.
- Enrutado con go_router y redirección por rol leído de `perfiles`; pantallas
  principales por rol como andamio temporal en `core/presentacion/pantallas/`.
- Esqueletos de `crear-cliente` y `dar-de-baja-cliente` con la validación de rol
  ya definitiva (`401`/`403` antes de instanciar `service_role`); la lógica de
  creación llega en la fase 3 y hoy devuelven `501`.
- CI en `.github/workflows/ci.yml`: build_runner + comprobación de que el código
  generado está comiteado, `dart format`, `dart analyze --fatal-infos`,
  `flutter test`, y un job aparte de `deno fmt`/`lint`/`check`.
- 55 tests: dominio puro, Notifiers con `mocktail`, redirección del enrutador y
  widget test del login.
- `supabase/seed.sql` con una cuenta de cada rol para poder probar CU-01 en
  local, ya que el alta de entrenador y administrador se hace desde el panel de
  Supabase y en local no hay panel.
- `riverpod_lint` activado por el bloque `plugins:` de `analysis_options.yaml`
  (sistema `analysis_server_plugin`).

**Corregido:**
- `missing_provider_scope` en `lib/main.dart`: la rama de configuración inválida
  llamaba a `runApp` sin `ProviderScope`. Lo detectó riverpod_lint en cuanto se
  ejecutó con el comando correcto.
- `authenticated` conservaba `TRUNCATE` sobre `clientes` y `ejercicios` por los
  privilegios por defecto del esquema `public`. `TRUNCATE` no pasa por RLS, así
  que era un borrado físico posible sobre tablas cuya baja debe ser lógica.
  Revocado junto con `TRIGGER` y `REFERENCES`.
- Funciones `security definer` sin `search_path` fijo: un usuario podía crear una
  tabla `perfiles` en `pg_temp` y hacer que `es_entrenador()` devolviera `true`
  (escalada de privilegios). Fijado `search_path = public, pg_temp`.
- `supabase/config.toml`: `auto_expose_new_tables = false` para que local se
  comporte como la nube. Sin esto, una migración a la que le faltara el `GRANT`
  funcionaría en local y fallaría en producción.
- Primera versión del seed dejaba en `NULL` las columnas de token de
  `auth.users`; GoTrue las lee como `text` no nulo y el login fallaba con un 500
  ("Database error querying schema") en vez de un 401. Se insertan como `''`.
- `AGENTS.md` indicaba `supabase db push` para aplicar migraciones en local; ese
  comando empuja a un proyecto remoto vinculado y falla con "Cannot find project
  ref". Para local es `supabase db reset` (o `supabase migration up`). Anadida
  al README una tabla de comandos locales vs. remotos del CLI: los remotos son
  los que fallan con `AccessTokenRequiredError` o `ProjectRefNotLinkedError`.
- El import `npm:@supabase/supabase-js@2` inline de `docs/architecture.md` viola
  la regla `no-import-prefix` de `deno lint`. Sustituido por el especificador
  simple que resuelve el import map de `supabase/functions/deno.json`.
- `SUPABASE_ANON_KEY` renombrado a `SUPABASE_PUBLISHABLE_KEY` en código, scripts
  y documentación. En Edge Functions no se renombra: el runtime no inyecta
  `SUPABASE_PUBLISHABLE_KEY` en singular, sino `SUPABASE_PUBLISHABLE_KEYS` (JSON
  `{"default": "..."}`), así que `clavePublicaDelProyecto()` la prefiere y cae a
  la heredada.

**Verificado:**
- Migraciones aplicadas desde cero en Supabase local. RLS probado suplantando
  cada rol: el cliente solo ve su ficha y no puede darse de baja (lo corta el
  `WITH CHECK`) aunque sí editar sus objetivos; el entrenador ve todas; el
  administrador ninguna (ausencia de política); nadie autenticado borra ni trunca;
  el cliente lee la biblioteca pero su `INSERT` viola RLS; `anon` no ve nada.
- Constraints de correo único entre activos y `baja_coherente` saltan como deben.
- Edge Functions con JWT reales de cada rol: `401` sin token y con token falso,
  `403` con rol cliente, `501` con entrenador y administrador, `400` en datos
  inválidos, `405` en GET y `204` en el preflight CORS.

- `scripts/probar_local.sh`: comprobacion end-to-end del entorno local (login de
  las tres cuentas, RLS por rol via API REST, ausencia de `DELETE` fisico y
  validacion de rol de las Edge Functions). 17 comprobaciones en verde.

- Un renombrado global de `SUPABASE_ANON_KEY` alcanzo el respaldo de
  `clavePublicaDelProyecto()` en la Edge Function y lo dejo apuntando a
  `SUPABASE_PUBLISHABLE_KEY`, variable que el runtime no inyecta (habria devuelto
  `undefined`). Restaurado, con un aviso en el comentario: esos nombres los fija
  Supabase, no el proyecto.
- Al lanzar desde el IDE la app arrancaba sin variables y mostraba la pantalla de
  configuracion incompleta: ninguna configuracion de ejecucion pasaba
  `--dart-define-from-file`. El `launch.json` estaba en `scripts/`, carpeta que
  VS Code no lee (solo `.vscode/launch.json`). Movido a `.vscode/launch.json`
  (ahora versionado) con configuraciones dev y prod, y anadido `additionalArgs` a
  `.idea/runConfigurations/main_dart.xml` por si se abre en Android Studio.
  Comprobado con `flutter test` con y sin el fichero: sin el, `esValida` es
  `false`; con el, `true`.

- Comentario de `clavePublicaDelProyecto()` y `supabase/functions/README.md`
  decian que `SUPABASE_ANON_KEY` tenia "nombre heredado, valor actual", dando a
  entender que contenia la clave publicable. Comprobado en el runtime: son
  valores distintos (`SUPABASE_ANON_KEY` es un JWT de 153 caracteres,
  `PUBLISHABLE_KEYS.default` es `sb_publishable_...` de 46). Redaccion corregida.

- `supabase/functions/.env` no estaba en ningun `.gitignore`: es la ruta que
  `supabase functions serve` lee por defecto, asi que la `RESEND_API_KEY` de la
  fase 3 se habria subido al repositorio. Anadidas reglas `.env` / `.env.*` en
  `supabase/.gitignore` y en el `.gitignore` raiz, con `!.env.example`, y creada
  la plantilla `supabase/functions/.env.example`.

- Anadido `.gitattributes` con `* text=auto eol=lf`: `core.autocrlf` estaba en
  `true`, asi que tras un clone o checkout en Windows los `.ts` habrian pasado a
  CRLF en disco y `deno fmt --check` habria fallado en local mientras pasaba en el
  CI de Linux. Incluye `eol=lf` explicito para `*.sh` (con CRLF no arrancan),
  marcas `binary` y `linguist-generated` para el codigo generado. Normalizados a
  LF los cinco archivos que seguian con CRLF en disco.
- Los `.sh` estaban versionados con modo 100644: en Linux habrian fallado con
  "Permission denied". Corregido a 100755 con `git update-index --chmod=+x`.

**Pendiente / notas:**
- `docs/sql-schema.md` usa `using (auth.role() = 'authenticated')` en la política
  de lectura de `ejercicios`; las migraciones usan `to authenticated`. Ambos
  funcionan igual en una petición normal de PostgREST, pero `auth.role()` devuelve
  `NULL` si la sesión no trae los claims del JWT y entonces deniega. Decidir si se
  unifica el doc.
- Solo `dart analyze` carga los plugins del sistema nuevo; `flutter analyze` los
  ignora en silencio. El comando de referencia del proyecto pasa a ser
  `dart analyze --fatal-infos` (varias reglas de riverpod_lint son `info`).
- CU-24 mantiene el mensaje genérico cuando el correo no está registrado, para no
  convertir el formulario en un comprobador de qué correos son clientes. Decisión
  confirmada; devolver un error explícito exigiría una Edge Function nueva.
- Falta crear a mano, en el panel de Supabase, la cuenta de entrenador y su fila
  en `perfiles` del proyecto de la nube (fuera del alcance de la app por diseño).
- El proyecto de producción no existe todavía: `config/prod.json` está vacío y
  `scripts/build_prod.sh` no funcionará hasta que se cree.
- Resend, pendiente de dominio verificado. Cuando lo haya: `RESEND_API_KEY` solo
  en `supabase/functions/.env` (local) y `supabase secrets set` o la interfaz web
  (nube, por proyecto: dev y prod aparte). Nunca en `.env.example`, que se
  versiona. Documentado en `supabase/functions/README.md`.
- Los secretos de GitHub Actions para el despliegue se configuran en la fase 6;
  el CI actual no necesita ninguno.
