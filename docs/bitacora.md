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

### 2026-09-30 (fase 2)

Biblioteca de ejercicios: RF-02 a RF-04, CU-02 a CU-04.

**Hecho:**
- Feature `biblioteca_ejercicios` con sus cuatro capas.
- `domain/`: `Ejercicio` (freezed), enums `TipoEjercicio` (fuerza/cardio) y
  `EstadoEjercicio` (activo/eliminado) alineados con los enums de Postgres,
  `DatosEjercicio` con las validaciones de CU-02 (nombre obligatorio y acotado,
  descripcion obligatoria porque la columna es `not null`, video opcional pero
  http(s) si se indica), `FiltroEjercicios` y la interfaz `EjercicioRepositorio`.
- `data/`: `EjercicioRepositorioSupabase`. Traduce el `23505` del indice
  `ejercicios_nombre_activo_unico` a `ErrorNombreDuplicado` y el `42501` de RLS a
  `ErrorNoAutorizado`. No expone ninguna operacion de borrado.
- `application/`: listado con filtros en memoria, controlador de formulario
  compartido por CU-02 y CU-03, y controlador de baja con la comprobacion de uso
  previa de CU-04.
- `presentation/`: listado con busqueda por nombre, grupo muscular y
  equipamiento, filtros por tipo y grupo, formulario de alta y edicion con el
  selector Fuerza/Cardio obligatorio, ficha de detalle y dialogos de CU-04.
- Vista de solo lectura para el cliente: es la misma pantalla sin acciones de
  escritura. Quien manda sigue siendo RLS, no la interfaz.
- Rutas `/entrenador/ejercicios` y `/cliente/ejercicios` como subrutas de cada
  rol, para que la redireccion por rol siga valiendo, y acceso desde las
  pantallas principales.
- Reactivacion de un ejercicio dado de baja (no es un CU del ERS, pero la baja
  logica lo hace trivial y evita que un descuido sea irreversible), con
  "Deshacer" en el aviso tras dar de baja.
- 48 tests nuevos (103 en total): validaciones de dominio, filtro, los dos
  controladores con `mocktail` y widget test del listado que comprueba que el
  cliente no ve alta, edicion ni baja.
- `scripts/probar_local.sh` ampliado con 17 comprobaciones de CU-02 a CU-04
  contra la API REST.

**Corregido:**
- `EstadoAccion` vivia en `features/autenticacion/application/` y ya lo usaban dos
  features. Movido a `lib/core/aplicacion/` para no acoplar features entre si.
- Tres fallos propios detectados por el analizador al integrar: `valueOrNull` no
  existe en Riverpod 3 (es `value`), faltaban imports del controlador del
  formulario en dos pantallas, y la tarjeta usaba `if (x case final y?)` donde
  ahora aplica el marcador `?x` (`use_null_aware_elements`).

**Pendiente / notas:**
- El punto 1 del encargo (migracion de `ejercicios`) ya estaba hecho: lo pedia el
  prompt de la fase 1. No se ha creado una segunda migracion porque repetir los
  `create type` habria fallado.
- CU-04 avisa de cuantos plannings activos usan el ejercicio, pero
  `contarUsosEnPlanningsActivos` devuelve 0 fijo: las tablas
  `ejercicios_planificados`, `bloques_ejercicio` y `plannings_semanales` llegan en
  la fase 4. El flujo de doble confirmacion ya esta, solo falta la consulta. Si la
  comprobacion falla se avisa de que no se ha podido comprobar, en lugar de dar
  por bueno que no esta en uso.
- El video de ejemplo se muestra y se copia al portapapeles, no se abre ni se
  incrusta: abrir una URL externa necesitaria `url_launcher`, dependencia nueva
  que hay que acordar antes.
- Sin verificar contra Supabase local: Docker Desktop estaba parado al terminar.
  Queda `./scripts/probar_local.sh` listo para ejecutarlo.

### 2026-10-01

**Corregido:**
- La app se quedaba sin responder al dar de baja un ejercicio (CU-04).
  `ControladorBajaEjercicio` es autoDispose y ninguna pantalla lo observaba: solo
  se leia con `ref.read(...notifier)` dentro del `onPressed`. Riverpod lo
  desechaba en cuanto terminaba ese `read`, asi que mientras el dialogo esperaba
  la confirmacion el notifier ya estaba muerto y su `ref.read` lanzaba
  `UnmountedRefException`. La excepcion salia en un `Future` que nadie capturaba,
  el flujo moria a medias y no ocurria nada: ni baja, ni mensaje de error.
  Tres cambios:
  - `PantallaBiblioteca` y `PantallaDetalleEjercicio` observan el provider con
    `ref.watch`, para que siga vivo mientras la pantalla lo esta.
  - `darDeBaja` y `reactivar` devuelven `Result<Ejercicio>` en vez de `bool`, y
    los dialogos usan ese valor en lugar de leer `state` despues. El estado de un
    provider autoDispose no es fiable entre dos dialogos.
  - El notifier comprueba `ref.mounted` antes de tocar `state` o `ref` tras un
    `await`, y los dialogos leen el notifier justo antes de cada uso en lugar de
    guardarlo en una variable al principio.
- `reactivarEjercicio` comprueba `context.mounted` antes de usar el `ref`: el
  "Deshacer" del aviso puede pulsarse cuando la pantalla de detalle ya se ha
  cerrado (hace `pop` tras la baja), y usar su `WidgetRef` desmontado lanza.

**Hecho:**
- 5 widget tests nuevos (108 en total) que recorren el flujo completo de CU-04
  por la interfaz (confirmar, cancelar, y la confirmacion adicional cuando esta en
  uso) y el alta y la edicion desde el listado. El primero de ellos reproducia el
  fallo antes del arreglo.

**Pendiente / notas:**
- El mismo patron (autoDispose leido solo con `ref.read` en un callback, con
  `await` de por medio) es facil de repetir en la fase 3: la pantalla que lance la
  operacion debe observar el controlador, y la operacion devolver su resultado en
  lugar de dejarlo en el estado.
- Sigue sin verificarse contra Supabase local: Docker Desktop estaba parado.

### 2026-10-01 (fase 3)

Gestion de clientes: RF-17 a RF-19, CU-17 a CU-19.

**Hecho:**
- `crear-cliente` completa (CU-17). Usa `generateLink` con tipo `invite`, que crea
  el usuario en Auth y devuelve el enlace SIN enviar correo, para poder mandarlo
  por Resend con plantilla propia en espanol. Despues inserta el perfil con rol
  `cliente` y la ficha. Responde `201 {clienteId, estado:"invitado"}` segun el
  contrato, mas `invitacionEnviada` y, si no salio, `avisoInvitacion`.
- **Compensacion en lugar de transaccion.** No hay transaccion posible que cubra
  los tres pasos: crear el usuario en Auth es una llamada HTTP a GoTrue, un
  servicio aparte, y cada peticion a PostgREST va en su propia transaccion. Si
  falla un paso posterior se llama a `auth.admin.deleteUser`, que por las FK con
  `on delete cascade` arrastra las filas de `perfiles` y `clientes`. Eso no
  contradice "bajas siempre logicas": no se da de baja a un cliente, se deshace un
  alta que no llego a completarse. Verificado provocando un desbordamiento de
  `numeric(5,2)`: no queda usuario, ni perfil, ni ficha.
- `_shared/correo.ts`: envio por Resend que NUNCA lanza. Si falta
  `RESEND_API_KEY` o la API responde error, el alta se mantiene y se informa de
  que la invitacion no salio. La ficha ya es valida y la invitacion se puede
  reenviar; fallar el alta obligaria a repetirla.
- `dar-de-baja-cliente` completa (CU-18): `estado='baja'`, `fecha_baja`, y
  `ban_duration` de 100 anos en Auth. Si el bloqueo falla, revierte la baja para
  no dejar una ficha de baja con acceso abierto.
- Feature `clientes` con sus cuatro capas: `Cliente` (freezed), enums `DiaSemana`
  y `EstadoCliente`, `DatosCliente` con validaciones, repositorio (alta y baja por
  Edge Function; lectura y edicion directas sujetas a RLS), controladores y
  pantallas de listado, ficha de detalle, formulario de alta/edicion y dialogos.
- El correo no se puede cambiar al editar (CU-19): identifica la cuenta de Auth, y
  cambiarlo dejaria la ficha desalineada con el acceso y la recuperacion.
- Validacion de altura y peso contra el limite de `numeric(5,2)` (999.99) antes de
  salir a la red, para no recibir un 500 por "numeric field overflow".
- El administrador puede dar de alta y de baja, pero su listado llega vacio: RLS
  no le da politica de lectura sobre `clientes`. La pantalla lo explica en lugar
  de parecer un error, y un widget test lo fija.
- 45 tests nuevos (153 en total) y 51 comprobaciones en
  `scripts/probar_local.sh`, todas en verde contra Supabase local.

**Corregido:**
- **`service_role` SI necesita `GRANT`.** `docs/sql-schema.md` afirmaba que "se
  salta tanto los permisos de tabla como RLS", y es falso: salta RLS (tiene
  `BYPASSRLS`) pero no los privilegios de tabla. Con la autoexposicion
  desactivada, las Edge Functions recibian `permission denied for table clientes`.
  Anadido `grant` a `service_role` en `perfiles` (select, insert) y `clientes`
  (select, insert, update), nunca `delete`, y corregido el doc.
- Punto 6 verificado end-to-end y blindado con tests: tras la baja, el login con
  la contrasena correcta devuelve `error_code: user_banned` con statusCode 400 —
  el mismo status que las credenciales invalidas. Si el `switch` mirara el status
  antes del codigo, el cliente de baja veria "correo o contrasena incorrectos" en
  lugar de "esta cuenta no esta disponible". Expuesto `traducirErrorAuth` para
  test y cubierto con 7 casos.
- Cuatro expectativas mal puestas en `scripts/probar_local.sh`: RLS en un UPDATE
  no devuelve 403 (afecta 0 filas y responde 2xx, hay que contar lo devuelto); el
  entrenador no puede leer perfiles ajenos, asi que esa comprobacion va contra la
  base de datos; y tres comprobaciones seguian esperando el 501 de cuando las
  funciones eran esqueletos.

**Pendiente / notas:**
- **Variables de entorno.** `RESEND_API_KEY` y `RESEND_FROM_EMAIL` siguen SIN
  valor real: no hay dominio verificado en Resend. El alta funciona y avisa de que
  la invitacion no sale (en local se vio "API key is invalid"). `APP_BASE_URL`
  apunta a local; cuando haya URL definitiva hay que ponerla ahi, porque es el
  `redirectTo` del enlace de invitacion. Las tres se configuran en
  `supabase/functions/.env` para local y con `supabase secrets set` para la nube.
- El punto 1 del encargo (migracion de `clientes`) ya estaba hecho en la fase 1.
- Un correo de un cliente dado de baja NO se puede reutilizar para un alta nueva:
  el indice unico de `clientes` solo aplica entre activos, pero Auth no admite dos
  usuarios con el mismo correo. La funcion devuelve 409 con un mensaje que lo
  explica. Reactivar a un cliente dado de baja no es un caso de uso del ERS;
  queda por decidir si se anade.
- CU-18 ya tiene el flujo de aviso por planning activo, pero
  `contarPlanningsActivos` devuelve 0 fijo hasta que exista `plannings_semanales`
  (fase 4), igual que el aviso de CU-04.

**Hecho (diagnostico):**
- `lib/core/diagnostico/`: registro de errores para desarrollo. Hacia falta porque
  la arquitectura es silenciosa por diseno —los repositorios traducen toda
  excepcion a `ErrorApp` y `ErrorInesperado` guardaba `causa` y `traza` que nadie
  leia nunca—, asi que un fallo real solo se veia como "ha ocurrido un error
  inesperado" sin forma de saber por que.
  - `Registro` extrae los campos que los errores de Supabase esconden (`code`,
    `details`, `hint` de PostgREST; `code` y `statusCode` de Auth; `status` y
    `details` de las Edge Functions) y solo escribe en modo debug.
  - `ObservadorProviders` registra los errores que viajan dentro de los providers,
    que al no lanzar excepcion no dejaban rastro.
  - Manejadores globales (`FlutterError.onError`, `PlatformDispatcher.onError` y
    `runZonedGuarded`) para lo que se escape de un `Future` sin `catch`.
  - Los tres repositorios registran la causa antes de traducirla.
- 5 tests del propio registro (158 en total) y seccion "Depuracion" en el README
  con donde mirar cada cosa.

**Corregido (flujo de invitacion, CU-17):**
- Un cliente invitado entraba en la app **sin fijar contrasena**, y luego no podia
  volver a entrar nunca. La causa esta en gotrue: `if (redirectType ==
  'recovery') passwordRecovery else signedIn`. Un enlace de invitacion lleva
  `type=invite`, asi que emitia `signedIn` y la app lo trataba como un login
  normal, enrutandolo a su pantalla principal. Como su cuenta se crea sin
  contrasena (verificado: `encrypted_password` vacio, `invited_at` puesto), al
  cerrar sesion se quedaba fuera y solo podia entrar por "he olvidado mi
  contrasena", que para el no tiene sentido.
  - `crear-cliente` marca al invitar con `data: {debe_fijar_contrasena: true}`.
  - El repositorio de autenticacion lo lee de `userMetadata`, y
    `ControladorSesion` devuelve el estado nuevo `SesionDebeFijarContrasena` antes
    incluso de resolver el perfil.
  - El enrutador lleva a la pantalla de contrasena, que ahora sirve a los dos
    flujos con textos distintos ("Elige tu contrasena" / "Nueva contrasena") y en
    el de invitacion no ofrece salir.
  - `establecerNuevaContrasena` limpia la marca en la misma llamada que fija la
    contrasena: hacerlo aparte podria dejar al cliente con contrasena pero
    atrapado en esa pantalla.
- Verificado end-to-end en local: el alta entrega el correo en Mailpit, el
  `action_link` redirige a `127.0.0.1:3000#access_token=...&type=invite`, y el JWT
  lleva `"debe_fijar_contrasena": true`.

**Hecho:**
- Respaldo de correo para desarrollo: sin `RESEND_API_KEY`, `correo.ts` entrega la
  invitacion en **Mailpit** por su API de inyeccion si hay `CORREO_DEV_URL`. Asi se
  prueba el flujo completo sin dominio verificado. La respuesta del alta lo indica
  con `entregadoEnBuzonLocal`.
- Puerto fijo `127.0.0.1:3000` en `run_dev.sh` y en `.vscode/launch.json`: GoTrue
  solo redirige los enlaces de invitacion y recuperacion a una URL permitida, y
  `flutter run` usaba un puerto aleatorio, con lo que el enlace nunca habria
  llegado a la app.
- 4 tests nuevos del flujo (171 en total) y seccion en el README.

**Pendiente / notas:**
- Las invitaciones ya creadas antes de este cambio no llevan la marca
  `debe_fijar_contrasena`, asi que esos clientes entrarian sin contrasena. En local
  se arregla con `supabase db reset`; en la nube habria que volver a invitarlos.

