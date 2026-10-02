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

### 2026-10-02 (fase 4)

Planificacion semanal: RF-05 a RF-16, CU-05 a CU-16.

**Hecho:**
- Tres migraciones nuevas, agrupadas por dependencia de FK:
  `20261002090000_plannings_y_sesiones`, `..._090100_bloques_y_ejercicios_planificados`
  y `..._090200_series`. Las seis tablas con sus indices unicos, constraints, RLS,
  `GRANT` y `revoke truncate/trigger/references`.
- `series_realizadas` creada en esta fase por integridad referencial, con sus
  politicas del cliente, pero **sin interfaz ni logica de escritura**: eso es CU-20.
  Sin `delete`: lo que el cliente registra es historico, se corrige con update.
- Los dos triggers de validacion, ambos con `set search_path = public, pg_temp`
  aunque no sean `security definer`: se ejecutan con los privilegios de quien
  escribe, y sin fijarlo una tabla homonima en `pg_temp` podria puentear la
  comprobacion. Lanzan con `errcode = 'check_violation'` para que el repositorio
  los distinga de un fallo cualquiera.
- Feature `planificacion_semanal` con sus cuatro capas. Cinco entidades freezed
  (`PlanningSemanal`, `SesionEntrenamiento`, `BloqueEjercicio`,
  `EjercicioPlanificado`, `SeriePlanificada`) y tres enums alineados con Postgres.
- El planning completo se trae **en una sola consulta** con relaciones incrustadas
  de PostgREST (planning → sesiones → bloques → ejercicios → ejercicio de biblioteca
  + series). Una semana cabe de sobra en memoria, y asi la pantalla valida fechas y
  ordenes duplicados sin ir al servidor. PostgREST no garantiza el orden de lo
  incrustado, asi que se ordena en el repositorio.
- Interfaz: historico de plannings por cliente (CU-23), vista de la semana con un
  dia por fila (los dias sin sesion se marcan como descanso), y formularios en
  dialogo para planning, sesion y bloque. El de ejercicio planificado va en pantalla
  propia porque su tabla de series no cabe en un dialogo.
- **El formulario de ejercicio cambia segun el tipo** (punto 6): al elegir un
  ejercicio de Fuerza se pintan series, peso, RIR y descanso; al elegir uno de
  Cardio, solo minutos. Los campos del otro tipo **no existen en el arbol de
  widgets**, asi que no hay forma de construir la combinacion imposible. El
  `aJson()` pone a `null` lo que no aplica, de modo que una edicion que cambie de
  tipo limpia los restos en lugar de dejar una fila que el trigger rechazaria.
- La misma pantalla sirve al cliente en modo lectura (punto 7): RLS ya le deja ver
  su planning y basto con no ofrecerle acciones. Un planning archivado tampoco
  admite cambios, ni para el entrenador.
- Archivar/reactivar planning como alternativa no destructiva a eliminarlo, y
  avisos de cascada en CU-13 a CU-16 que dicen cuantas sesiones y ejercicios se
  van a perder.
- 52 tests nuevos (223 en total): validaciones de dominio, el controlador con
  `mocktail` y widget tests del formulario que comprueban que el campo de minutos
  no existe para Fuerza y que el de series no existe para Cardio.
- `scripts/probar_local.sh` ampliado a 74 comprobaciones, con los dos triggers, los
  indices unicos, el rango de RIR y la cascada de borrado.

**Pendiente / notas:**
- **Las migraciones de esta fase NO se han aplicado todavia**: Docker Desktop se
  cerro a mitad y no se pudo arrancar Supabase local. El SQL esta sin ejecutar ni
  una vez, asi que puede tener errores de sintaxis. Hay que correr
  `supabase db reset` y despues `./scripts/probar_local.sh`.
- Los triggers de recalculo de `estado_registro` y `resultado_registrado` no se
  crean aqui: solo tienen efecto cuando el cliente registra resultados (CU-20) y el
  propio `sql-schema.md` deja pendiente completar el caso de cardio con un tercer
  trigger `after update`. Se resolveran juntos en la fase 5.
- `_reemplazarSeries` (borrar las anteriores e insertar las nuevas al editar) no es
  atomico: PostgREST no agrupa dos peticiones en una transaccion. En el alta se
  compensa borrando el ejercicio; en la edicion, si falla el insert el ejercicio se
  queda sin series y el entrenador tiene que volver a guardar. Una funcion RPC lo
  resolveria.
- Sigue pendiente la migracion correctiva de los `grant ... to service_role`, que en
  la fase 3 se anadieron editando migraciones ya aplicadas en lugar de creando una
  nueva.

**Corregido:**
- La app no arrancaba: `SocketException ... errno = 10013` al bindear el 127.0.0.1:3000
  que yo habia fijado en el turno anterior. No era que el puerto estuviera ocupado
  (no habia nada escuchando): Windows lo tenia **reservado**. Hyper-V y Docker
  reservan bloques del rango dinamico de TCP, que en esta maquina va de 1024 a 15000,
  y el 3000 cayo dentro del bloque 2919-3018. Esos bloques se reasignan al
  arrancar o parar Docker, de ahi que antes funcionara.
  - Puerto cambiado al **54330**, fuera del rango dinamico, asi que no puede quedar
    reservado. Actualizado a la vez en `scripts/run_dev.sh`,
    `.vscode/launch.json`, `site_url` y `additional_redirect_urls` de
    `supabase/config.toml`, y `APP_BASE_URL` del `.env` y su plantilla: si no
    coinciden todos, los enlaces de invitacion y recuperacion no llegan a la app.
  - De paso, `additional_redirect_urls` tenia `https://` en una URL local, donde no
    hay TLS; ahora es `http://`.
  - Documentado en el README con el comando para ver los bloques reservados.

**Hecho (cierre de la fase 4):**
- Migraciones de la fase 4 **verificadas**: las ocho aplican limpias con
  `supabase db reset` y el script local pasa **89/89**.
- `guardar_ejercicio_planificado`, funcion de Postgres que guarda el ejercicio y
  sus series en **una sola transaccion**. Sustituye a las tres peticiones que hacia
  el repositorio (upsert, borrar series, insertar series), cada una en su propia
  transaccion. Es `security invoker`, asi que RLS y los triggers siguen actuando
  dentro: verificado que un cliente que la invoque recibe
  "violates row-level security policy", y que `anon` no puede ni ejecutarla.
  Verificada la atomicidad: una serie con RIR 11 tumba la operacion completa y las
  series anteriores quedan intactas, aunque la funcion las borre antes de insertar.
- Los cuatro triggers de recalculo de `estado_registro` y `resultado_registrado`,
  incluido el que el doc dejaba pendiente para Cardio. Son `security definer`
  porque al registrar una serie hay que escribir en
  `sesiones_entrenamiento.resultado_registrado`, y las politicas de esa tabla solo
  dan `update` al entrenador: con `security invoker` el registro del cliente
  fallaria. No aceptan datos del usuario, solo recalculan valores derivados.
- `grant select` a `service_role` en las seis tablas de planificacion. Hoy ninguna
  Edge Function las toca, pero el recordatorio de CU-22 (fase 6) tendra que leer las
  sesiones del dia siguiente, y asi no se repite el tropiezo que bloqueo
  `crear-cliente` en la fase 3.
- El script local sube a 89 comprobaciones, con los triggers y la atomicidad de la
  RPC, y avisa si el cliente del seed esta de baja en lugar de fallar en cascada:
  el propio script lo da de baja al comprobar el bloqueo de acceso, asi que una
  segunda pasada necesita `supabase db reset`.

**Corregido:**
- El trigger `propagar_estado_registro` estaba declarado como
  `after update OF estado_registro`, y asi **no se disparaba nunca** en el camino de
  Cardio: Postgres decide `UPDATE OF columna` por las columnas **mencionadas en la
  sentencia**, no por las que cambian. El registro de cardio es
  `update ... set minutos_realizados = X`, y es el trigger `before` quien toca
  `estado_registro`. Resultado: el ejercicio quedaba registrado pero la sesion nunca
  se marcaba como completa. Quitado el `OF`; el `when` si compara los valores reales.
  Lo encontro la prueba de los triggers, no la revision del codigo.
- Dos fallos en el propio script de pruebas, que daban falsos negativos: `psql`
  necesita `-q` o un `insert ... returning id` pega la linea de estado
  ("INSERT 0 1") al uuid y lo corrompe; y el bloque no limpiaba los restos de la
  pasada anterior, con lo que el indice unico de planning por semana lo tumbaba.

**Hecho (preparando la fase 5):**
- El cliente ya puede entrar a su planning: nueva pantalla `PantallaMisPlannings`
  (`/cliente/planning`), con sus semanas activas y el historico de las archivadas.
  Abre la semana con la misma `PantallaPlanning` del entrenador, que ya decide por
  rol si ofrece acciones de escritura, asi que el cliente la ve en solo lectura sin
  duplicar pantalla.
- La tarjeta de la semana en curso dice **lo que toca hoy** ("Hoy: Empuje · 4
  ejercicios" o "Hoy toca descanso"). La lista de plannings es una consulta plana,
  sin sesiones, asi que para eso observa `planningCompletoProvider`: es la misma
  peticion que hara la pantalla de la semana al abrirla, con lo que no se repite.
- Providers nuevos: `idUsuarioActual` (en `controlador_sesion`) y `misPlannings`.
  Este ultimo **no recibe el id del cliente por parametro**, lo toma de la sesion:
  asi la pantalla del cliente no puede pedir el historico de otro ni por error. RLS
  ya lo impide en el servidor; esto evita siquiera intentarlo.
- Verificado contra Supabase local que la politica "el cliente ve sus propios
  plannings" cubre justo la consulta que hace `listarDeCliente`: impersonando por
  `request.jwt.claims`, el dueno ve su planning y otro cliente ve 0 filas (todo
  dentro de una transaccion con `rollback`, sin tocar los datos locales).
- 6 tests de widget nuevos (229 en total), `dart analyze --fatal-infos` limpio.
  Sin cambios de esquema ni de RLS: todo lo que hace falta ya estaba de la fase 4.

**Pendiente / notas:**
- **Bucket de Storage de las fotos de progreso**: se decide crearlo por
  configuracion, no a mano. En local va en `[storage.buckets.fotos-progreso]` de
  `supabase/config.toml` (`public = false`), y en la nube hay que crearlo tambien
  desde el panel: lo del panel no existe en local. Al ser privado **no hay URL
  publica**; `ruta_storage` guarda la ruta y la foto se muestra con una URL firmada
  y caducable. Un bucket publico dejaria ver las fotos a cualquiera que conociera la
  ruta, incluido el administrador, que por ERS no debe tener acceso.
- La captura que paso Daniel (app de gimnasio, con historico de series arriba e
  inputs de peso/reps con +/- abajo) queda como **diseno de referencia para la
  pantalla de registro de serie de CU-20**, que es ya fase 5.
- Bucket `fotos-progreso` declarado en `config.toml` (Daniel) y comprobado en
  local: privado, 20 MiB, png/jpeg. Le quite el `objects_path = "./images"` que
  venia del ejemplo comentado: precarga en el bucket los ficheros de esa carpeta y,
  si no existe, el sembrado falla con `NotFound: FileSystem.stat`. La carpeta
  estaba vacia, y git no versiona carpetas vacias, asi que en una copia recien
  clonada o en CI el arranque habria fallado. Verificado el fallo y verificado que
  sin esa linea `supabase seed buckets --local` deja el bucket actualizado.
- Para la nube, `supabase config push` empuja lo declarado en `config.toml` al
  proyecto enlazado; queda por confirmar cuando exista el proyecto.
