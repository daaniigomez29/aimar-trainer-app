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

### 2026-10-03 (fase 5)

**Hecho:**
- **Migraciones nuevas (5)**: `registros_medidas` + `fotos_progreso`,
  `checkins_recuperacion`, politicas del bucket sobre `storage.objects`,
  `registrar_resultado_ejercicio` (RPC de CU-20) y las vistas de progreso. Las 13
  aplican limpias con `supabase db reset`.
  - `series_realizadas` y los cuatro triggers de recalculo **ya estaban** desde el
    cierre de la fase 4, incluido el `after update` que el doc dejaba pendiente para
    cardio: en esta fase solo se les ha dado uso real.
  - Ninguna politica para `es_administrador()` en ninguna de las tablas nuevas, ni
    en el bucket. Verificado por la API que no ve absolutamente nada.
- **CU-20**: el cliente abre la sesion desde su planning y registra ejercicio a
  ejercicio. La pantalla de Fuerza sigue la captura que paso Daniel: historico
  arriba (lo planificado, lo confirmado hoy y las dos ultimas sesiones del mismo
  ejercicio) y abajo peso, repeticiones y RIR con botones de mas y menos. El boton
  grande confirma la serie y pasa a la siguiente. Cardio tiene su propio cuerpo con
  los minutos. Un ejercicio puede quedarse a medias: se guarda lo confirmado.
- **CU-21**: pantalla de progreso con filtro por ejercicio y metrica (peso maximo,
  volumen, repeticiones, RIR medio; minutos en cardio) o por medida corporal, mas
  rango de fechas. La grafica esta pintada con `CustomPainter`: no se ha anadido
  ninguna libreria de graficas. Misma pantalla para el cliente (lo suyo, desde su
  inicio) y para el entrenador (desde la ficha del cliente).
- **Medidas y check-in**: una pantalla de control semanal que abre por defecto en el
  `diaControlPreferido` del cliente, con los **dos formularios independientes**,
  cada uno con su boton y su resultado. Rellenar solo uno es valido, como dice el
  modelo de dominio. Fotos de progreso con subida al bucket privado y miniaturas
  por URL firmada.
- **Conversion de imagen**: la app nunca sube el fichero original. Lo decodifica,
  lo reduce a 1600 px de lado mayor y lo recodifica en PNG antes de subir
  (`ServicioImagenes` en `core/plataforma`, con `image_picker` para elegir y
  `dart:ui` para convertir). Asi un HEIC de iPhone no llega nunca al bucket, que
  solo admite PNG y JPEG. Documentado en `architecture.md`.
- **Dependencia nueva**, consultada antes: `image_picker`. Es la unica; la grafica y
  la conversion no han necesitado ninguna.
- `scripts/probar_local.sh` pasa de 89 a **128 comprobaciones**: medidas, check-in,
  la RPC de registro, el planning archivado, las vistas y el bucket, cada una con su
  caso de cliente, entrenador y administrador.
- 43 tests nuevos (272 en total), `dart analyze --fatal-infos` limpio.

**Corregido:**
- En Cardio no se precargaban los minutos planificados en el formulario de registro,
  mientras que en Fuerza si se precargaban las series: el cliente tenia que teclear
  un valor que la app ya conocia, y si le daba a guardar sin escribir nada se
  llevaba un error de validacion. Lo encontro el test de widget, no la lectura del
  codigo.
- `objects_path = "./images"` en el bucket de `config.toml` (venia del ejemplo
  comentado): apunta a una carpeta cuyo contenido se precarga en el bucket y, si no
  existe, el arranque falla con `NotFound: FileSystem.stat`. La carpeta estaba vacia
  y git no versiona carpetas vacias, asi que en una copia recien clonada habria
  fallado. Quitado.

**Pendiente / notas:**
- **Consecuencia del diseno, a confirmar**: `series_realizadas` no tiene `delete`,
  asi que el cliente puede corregir una serie pero no quitarla. Si registra 3 y
  luego solo hizo 2, la tercera se queda. La RPC usa `on conflict do update` por eso.
- **El 500 de la RPC** cuando el ejercicio no es visible: lanza `no_data_found`
  (P0002) y PostgREST no traduce ese SQLSTATE a un estado HTTP. La app no se guia
  por el codigo HTTP sino por el `code` del cuerpo, asi que muestra el mensaje
  correcto. Si se quisiera un 404 limpio habria que usar los codigos `PTxxx` de
  PostgREST, y entonces conviene cambiar tambien
  `guardar_ejercicio_planificado` para no dejar dos convenciones.
- Corregir el resultado de un **planning archivado** no es posible: el `on conflict`
  evalua tambien la politica de `insert`, que exige planning activo. Registrar en
  una semana archivada ya estaba prohibido por diseno; corregir lo registrado antes
  de archivarla, no. No es un caso de uso del ERS.
- El bucket solo admite PNG y JPEG; la app sube siempre PNG. Si algun dia se quiere
  JPEG (pesa bastante menos en fotos), `dart:ui` no lo codifica: haria falta otra
  via.

**Corregido (despues de cerrar la fase 5, al probar en la app):**
- **El planning se veia como una semana entera de descanso.** `PlanningSemanal.sesiones`
  no tenia `@JsonKey(name: 'sesiones_entrenamiento')`, y PostgREST devuelve los
  recursos incrustados con el **nombre de la tabla**, no con el del campo. Con
  `@Default([])` la lista llegaba vacia **en silencio**: ningun dia mostraba su
  sesion, todos ofrecian "Anadir sesion", y al intentar crearla el indice unico de
  la base la rechazaba con "Ya hay una sesion en esa fecha". Los tres niveles de
  abajo (`bloques_ejercicio`, `ejercicios_planificados`, `series_planificadas`) si
  lo tenian; se le olvido al de arriba. Es un fallo de la fase 4.
  - **Por que no lo vio nada**: el script de pruebas va por la API REST y no pasa
    por las entidades; los tests de widget construyen las entidades a mano, asi que
    tampoco parsean JSON. El agujero estaba entre los dos.
  - Test nuevo `planning_json_test.dart` con la **respuesta real** capturada de
    Supabase local: comprueba los cuatro niveles y que `sesionDe` encuentra la
    sesion del dia. Es el que habria cazado esto.
  - Tambien `pantalla_planning_test.dart`, que fija que la semana pinta sus
    sesiones. Ojo: hay que **agrandar el viewport** en estos tests; con los 600 px
    por defecto un `ListView` solo construye los primeros dias y el test dice que
    faltan sesiones cuando no es verdad.
- Revisados todos los demas campos de lista que salen de un recurso incrustado
  (`bloques`, `ejercicios`, `series`, `seriesRealizadas`, `fotos`): sus claves
  generadas son correctas.

**Hecho (fase 6, CU-22):**
- **Edge Function `enviar-recordatorios`**: busca las sesiones de manana en
  plannings activos y los clientes cuyo dia de control es hoy, y avisa por correo
  (siempre) y por push (si el cliente lo tiene activado). Calcula "hoy" y "manana"
  en **Europe/Madrid**, no en UTC: a las 23:30 de Madrid en verano, en UTC todavia
  es el dia anterior y "manana" saldria mal.
- **Job diario de pg_cron** a las 17:00 UTC (19:00 en Espana en verano, 18:00 en
  invierno), que invoca la funcion por `pg_net`. La URL y el secreto estan en
  **Vault**, no en la migracion: cambian por entorno y el secreto no debe vivir en
  el repositorio. `seed.sql` los crea para local.
- **La funcion no acepta JWT de usuario**: quien la llama es un job. Se identifica
  con la cabecera `x-secreto-cron`. Sin `SECRETO_CRON` configurado devuelve 500 y
  no atiende a nadie, en vez de quedarse abierta.
- **Tres tablas**: `preferencias_notificacion`, `suscripciones_push` y
  `avisos_enviados`. Esta ultima es la que cumple la excepcion de CU-22: un push
  que no se manda porque el cliente lo tiene apagado queda como **`omitido`** con
  su motivo, no se pierde. Indice unico por cliente, tipo, canal y fecha: si el
  job se dispara dos veces, el segundo no reenvia.
- **Push web con VAPID, sin proveedor de terceros y sin dependencias nuevas en
  Flutter**: el puente con `PushManager` esta en `web/index.html` y se llama con
  `dart:js_interop` desde `servicio_push_web.dart`, detras de la interfaz
  `ServicioPush`. El service worker del push es propio (`web/push_sw.js`) y se
  registra en el ambito `push/`, porque el de Flutter ocupa la raiz y lo regenera
  cada build.
- **Pantalla de preferencias** para el cliente, con interruptor solo para el push.
  El correo aparece como "siempre activo" y sin interruptor, con su explicacion:
  es el canal de respaldo.
- `probar_local.sh` pasa de 128 a **153 comprobaciones**. Entre ellas, que un
  cliente dado de baja no recibe avisos, que el segundo disparo no reenvia, y que
  el job llega de verdad hasta la funcion (Vault -> pg_net -> Kong -> funcion).
- 7 tests nuevos (288 en total).

**Corregido:**
- Nada roto por el camino, pero si dos cosas que solo se ven ejecutando:
  `npm:web-push` no se puede importar con el especificador en linea (lo prohibe
  `deno lint`), va por el import map de `deno.json`; y Dart **no deja hacer un
  tear-off de un miembro externo de JavaScript**, cosa que `dart analyze` no ve
  porque analiza la rama no-web del import condicional: lo caza `flutter build web`.

**Pendiente / notas:**
- **La rama de "suscripcion caducada" (404/410) no esta probada de punta a punta.**
  `web-push` fuerza https, asi que no se puede apuntar un endpoint de prueba al
  Kong local, que va por http. El codigo que borra la suscripcion caducada esta
  escrito y revisado, pero hace falta un navegador real para verlo. Queda para la
  primera prueba en la nube.
- **El envio real de un push no se ha podido probar en local** por lo mismo: hace
  falta una suscripcion real de navegador. Lo que si esta verificado es que la
  firma VAPID y el cifrado se ejecutan (el fallo llega en el paso de red, no antes)
  y que los estados `omitido` y `fallido` se registran bien.
- **`deno check` falla en `crear-cliente`** (TS2353: `data` no existe en
  `GenerateInviteOrMagiclinkParams`). Es de la fase 3, no de esta, y **funciona en
  tiempo de ejecucion**: el flujo de invitacion esta verificado. Es un desajuste
  entre los tipos de `supabase-js` y lo que acepta GoTrue; el arreglo seria mover
  `data` dentro de `options`, pero toca una Edge Function ya verificada y no se ha
  tocado sin acordarlo.
- Las claves VAPID de local estan en `supabase/functions/.env` (ignorado por git).
  **Produccion necesita un par propio**, generado con
  `deno eval "import w from 'npm:web-push@3.6.7'; console.log(JSON.stringify(w.generateVAPIDKeys()))"`.

### 2026-10-04

**Hecho:**
- **La entidad Ejercicio gana una imagen ilustrativa** (atributo nuevo de la
  entidad 5, pedido despues de cerrar las seis fases): columna `imagen_ruta` y
  bucket **publico** `imagenes-ejercicios`.
  - Publico a proposito, al contrario que `fotos-progreso`: no es dato personal,
    la ven todos los clientes y se pinta en una lista. Con un bucket privado
    habria que firmar una URL por ejercicio cada vez que se abre la biblioteca, y
    ninguna se podria cachear. Lo que si esta restringido es escribir: subir,
    reemplazar y borrar solo el entrenador, por politicas sobre `storage.objects`.
  - La columna guarda la **ruta**, no la URL: el dominio cambia entre local y la
    nube y la arma el repositorio con `getPublicUrl`.
- La imagen se elige en el formulario y **se sube al guardar, no al elegirla**:
  subir al elegir dejaria ficheros sueltos en el bucket cada vez que alguien abre
  el formulario y se arrepiente. Mientras tanto se previsualiza desde memoria.
  Si el guardado falla despues de subir, se borra el fichero; al reemplazar una
  imagen, se borra la anterior.
- Reutiliza el `ServicioImagenes` de la fase 5, asi que la imagen tambien se
  convierte a PNG y se reduce a 1600 px antes de subirse: un HEIC de iPhone no
  llega al bucket.
- Se muestra en la ficha del ejercicio (a tamano completo, con `BoxFit.contain`
  para no recortar justo la parte que importa) y como miniatura en el listado.
- `probar_local.sh` sube a **162 comprobaciones**: que el entrenador sube y borra,
  que el cliente y el administrador no pueden, que la imagen se lee **sin token**
  (lo que confirma que el bucket es publico de verdad) y que la columna rechaza
  una ruta en blanco.
- 5 tests nuevos del controlador (293 en total), incluidos los de compensacion al
  fallar y el borrado de la anterior al reemplazar.

**Pendiente / notas:**
- `imagenes-ejercicios` hay que **crearlo tambien en la nube** cuando se despliegue,
  igual que `fotos-progreso`. Sus politicas si viajan en la migracion.
- Al dar de baja un ejercicio **no se borra su imagen**: la baja es logica y el
  ejercicio sigue visible en los plannings que ya lo usaban, asi que la ilustracion
  debe seguir estando.

**Hecho (mismo dia, vuelta al video de ejemplo):**
- **El video se ve dentro de la app**, sin saltar a YouTube. Sustituye a la
  solucion provisional de la fase 2, que solo copiaba el enlace al portapapeles
  porque abrirlo habria necesitado `url_launcher`.
- Montado como **vista de plataforma**: Flutter web pinta sobre un canvas, asi que
  el iframe no se puede crear desde Dart. El elemento lo crea un factory en
  `web/index.html` y `reproductor_video_web.dart` lo registra con
  `ui_web.platformViewRegistry`. **Sin dependencias nuevas**, igual que el push.
  El registro se guarda en un `Set` porque registrar dos veces el mismo tipo de
  vista lanza.
- `VideoEjemplo` (dominio, sin plataforma) saca el identificador de las cinco
  formas en las que YouTube reparte el mismo video (`shorts/`, `watch?v=`,
  `youtu.be/`, `embed/`, `live/`), con sus parametros de compartir pegados detras.
- Se usa el dominio **sin cookies** (`youtube-nocookie.com`) y `rel=0` +
  `playsinline=1`: no deja rastro en el navegador mientras el cliente no le de al
  play, limita las sugerencias del final y evita que iOS se lleve el video a
  pantalla completa por su cuenta. Relacion 9:16 por defecto, que es lo que graba
  el entrenador.
- **Verificado en el navegador**, no solo compilado: servido el build de `web/` y
  abierta la ficha de un ejercicio, el iframe monta a 320x569 con la URL correcta y
  el video carga. De paso se vio el caso del video cuyo dueno **no permite
  incrustar**: YouTube muestra su propio aviso y por eso el enlace copiable se
  queda debajo, no se quita.
- 9 tests nuevos del parseo de URL (302 en total).

**Pendiente / notas:**
- Un enlace que no sea de YouTube (Vimeo, un mp4 suelto) **no se reproduce**: se
  queda como enlace copiable, como hasta ahora. No es un caso de uso del ERS.

**Hecho (diseno visual, docs/ui-design.md):**
- **Tema**: `lib/core/theme/` con los tokens exactos del doc (`tokens.dart`) y el
  `ThemeData` oscuro unico para los dos roles (`tema_app.dart`), con Space Grotesk
  para titulos e IBM Plex Sans para el cuerpo. Dependencia nueva: `google_fonts`.
  Sustituye al `core/presentacion/tema.dart` anterior, que se ha borrado.
- **Componentes comunes** antes que las pantallas: `Tarjeta`, `ChipFiltro`,
  `SliderConValor`, `FilaInterruptor`, `BotonCta`, `Pastilla`, `ProgresoCircular`
  y `CampoBusqueda` (`core/presentacion/widgets/componentes.dart`), mas las barras
  de navegacion de los dos roles y el andamio `PantallaCliente`
  (`widgets/navegacion.dart`).
- **1. Mi planning (cliente)**: nueva pantalla de entrada en `/cliente`, con tira
  de dias, sesion de hoy, progreso circular y los dos datos rapidos. Sustituye al
  panel de accesos. El historico de semanas sigue a un toque, desde el reloj de la
  cabecera.
- **2. Registro de ejercicio**: rehecho segun la captura. Cada serie es una tarjeta
  con su plan en ambar y su propio check; confirmar sigue enviando la lista
  completa de series confirmadas, que es lo que hace la llamada idempotente.
- **3. Control semanal**: ahora son **dos pasos**, uno visible a la vez. Siguen
  siendo dos guardados independientes: "Continuar" guarda las medidas, el boton del
  paso 2 guarda el check-in. La flecha atras conserva lo escrito (verificado en el
  navegador).
- **4. Biblioteca**: buscador y chips por grupo muscular, que salen de los datos y
  no de una lista fija (el grupo es texto libre en la entidad).
- **5. Configuracion**: interruptor de push y tarjeta de correo "siempre activo".
- **6 y 7. Planificacion del entrenador**: una sola pantalla para escritorio
  (barra lateral + panel de biblioteca fijo) y movil (barra inferior + modal). Es
  ahora la pantalla de entrada del entrenador.

**Corregido:**
- **El cliente se habia quedado sin cerrar sesion**: el boton vivia en la pantalla
  de accesos que sustituye "Mi planning". Anadido a Configuracion.
- La baja de un ejercicio desde el listado (CU-04) desaparecio al rehacer la fila;
  restaurada. Las capturas son de la biblioteca **del cliente**, que solo consulta.
- Etiquetas de la barra inferior cortadas en 375 px: se anade una etiqueta corta
  para la barra ("Control", "Ajustes", "Planning").
- Barra superior del entrenador en movil: no cabian selector, semana y boton en una
  fila; ahora se apilan.
- Los botones "+" del panel de biblioteca salian en ambar, que en este sistema
  significa "planificado". Pasados a acento.
- Una serie extra en el registro nacia vacia; ahora copia lo de la serie anterior.
  Lo destapo el test, no la lectura del codigo.

**Ajustes respecto a las capturas (manda el dominio):**
- **"Guardar cambios" del entrenador** solo agrupa los valores de las series. Crear
  la semana, anadir o quitar sesion, bloque o ejercicio se guardan al momento:
  cada una es una operacion atomica en base de datos y no tiene sentido dejarla
  esperando a un boton. El boton se deshabilita y dice "Todo guardado" cuando no
  queda nada pendiente.
- **"Nota de Aimar"**: en el modelo no hay notas por ejercicio; las notas viven en
  el **bloque** (entidad 4), y es esa la que se muestra.
- **"En curso"** no es un estado del dominio (`estado_registro` solo es pendiente o
  registrado): el ejercicio marcado como en curso es el primero sin registrar, y es
  solo presentacion.
- **"45-55 min" y "13 ejercicios"** de las capturas son datos inventados del
  prototipo: no hay duracion estimada en el modelo, asi que se muestra lo que si
  existe (numero de ejercicios, y cuantos tienen video).
- **Las fotos de progreso** no aparecen en el prototipo del control semanal, pero
  si en el dominio (entidad 9): se mantienen en el paso 1.

**Pendiente / notas:**
- Las pantallas que no estaban en la lista (detalle y formulario de ejercicio,
  clientes, progreso, historico de semanas, login) **heredan el tema** pero no se
  han rediseñado una a una.
- `lib/core/theme/` queda con nombre en ingles, al lado de `core/presentacion/`.
  Lo pedia el prompt tal cual; si se prefiere coherencia con el resto, renombrarlo
  a `core/tema/` es un cambio mecanico.
- El Supabase local se ha quedado con datos de ejemplo (cliente "Marta Lopez", 9
  ejercicios, una semana con la sesion "Empuje A"). `supabase db reset` los quita.

**Corregido (mismo dia, lo reporto Daniel):**
- **La navegacion desaparecia al entrar en Biblioteca o en Clientes.** Al rehacer
  las pantallas puse el armazon con barra lateral solo en Planificacion, asi que
  el entrenador se quedaba sin ninguna navegacion a la vista en los otros
  destinos: en Clientes no habia barra de ningun tipo, y en Biblioteca solo
  aparecia la inferior en movil (en escritorio, ninguna).
  - Arreglado con un andamio compartido, `PantallaEntrenador`, que pone barra
    lateral en escritorio y barra inferior en movil. Lo usan ahora Biblioteca,
    Clientes y Ajustes, igual que `PantallaCliente` hace con las cinco del
    cliente.
  - **Mi progreso del cliente tenia el mismo fallo** y no se habia visto: montaba
    su propio `Scaffold` sin barra inferior. La misma pantalla la usa el entrenador
    desde la ficha de un cliente, y ahi **no** debe llevar barra (llega empujada y
    se vuelve con la flecha), asi que se distingue por si recibe `titulo`.
  - El administrador entra tambien a Clientes y se queda con la pantalla suelta:
    su navegacion no es la del entrenador.
- De paso, en escritorio la barra lateral llega hasta arriba: la cabecera va dentro
  de la columna de la derecha, no como `appBar` del Scaffold.
- **Editar un ejercicio dejaba la pantalla en negro.** El tema ponia
  `minimumSize: Size.fromHeight(48)` a los `OutlinedButton`, y eso es ancho
  **infinito**: el boton de elegir imagen que anadi al formulario vive dentro de
  una `Row`, que no acota el ancho, y el layout reventaba ("BoxConstraints forces
  an infinite width"). En Flutter eso no se ve como un error, se ve como una
  pantalla negra.
  - Arreglado en los dos sitios: el tema pasa a `Size(0, 48)` (alto minimo, sin
    forzar ancho) y la columna de botones del formulario va dentro de un
    `Expanded`. Los botones que deben ocupar el ancho completo ya lo piden ellos
    (`BotonCta` lo hace con un `SizedBox`).
  - El `FilledButton` del tema **si** mantiene el ancho completo, porque es lo que
    pide el diseno para los CTA. Comprobado que dentro de las acciones de un
    `AlertDialog` no rompe: el `OverflowBar` si acota el ancho.
  - **Test nuevo** del formulario de ejercicio (alta, edicion, con imagen y sin
    ella). No tenia ninguno: por eso un fallo que tumba la pantalla entera pasaba
    con los 302 tests en verde.

**Hecho (sesiones numeradas, no fechadas):**

- La sesion de entrenamiento **deja de colgar de una fecha del calendario** y pasa
  a numerarse dentro de su planning: Dia 1, Dia 2, Dia 3, con un boton "+" al final
  de la tira para anadir la siguiente. El motivo es del gimnasio, no tecnico: el
  entrenador planifica "cuatro sesiones esta semana", y si el cliente no puede ir el
  miercoles y acaba yendo el jueves es la misma sesion, no una desplazada.
- Esto **invierte una regla de la fase 4** ("la planificacion se hace sobre un
  calendario", `AGENTS.md`). Cambio pedido explicitamente; los documentos van con el:
  `AGENTS.md`, `docs/domain-model.md` (entidad 3), `docs/sql-schema.md`,
  `docs/requirements.md` (RF-06, CU-06, CU-22) y `docs/estado-actual.md`.
- Migracion `20261004100000_sesiones_por_orden.sql`: `orden integer not null check
  (orden > 0)` con indice unico `(planning_id, orden)`, fuera la columna `fecha`, el
  trigger `comprobar_fecha_sesion` y su funcion. Las sesiones que ya existian se
  numeran por la fecha que tenian, que es el orden en que el entrenador las penso.
- **La fecha no desaparece del todo**: nueva columna `fecha_realizada`, el dia en que
  el cliente **hizo** la sesion, que es un dato distinto del que habia. Nullable, la
  rellena `recalcular_resultado_sesion` en cuanto hay un ejercicio registrado, y la
  app no la escribe nunca. Con `coalesce`, para que sea la del primer registro y no
  la del ultimo, y en `Europe/Madrid`. Si el cliente deshace todo lo registrado,
  vuelve a `null`: la sesion no se hizo.
- Hoy `fecha_realizada` **no condiciona ninguna regla**, como se pidio: solo queda
  guardada. Lo unico que la usa son las vistas de CU-21, que necesitan un eje
  temporal y antes tiraban de la fecha planificada; ahora filtran las sesiones que
  aun no tienen fecha.
- En Flutter: `SesionEntrenamiento` cambia `fecha` por `orden` + `fechaRealizada`;
  `DatosSesion` valida nombre y numero libre en vez de fecha dentro de la semana; el
  dialogo propone el numero que toca y ya no tiene desplegable de dia. Las tres
  pantallas que pintaban dias de la semana (planning del cliente, planificacion del
  entrenador y detalle del planning) pintan "DIA N", y la del cliente anade
  "HECHA EL dd/MM" cuando la hay.

**Corregido:**

- **CU-22 avisaba de "manana tienes sesion"**, y eso ya no se puede saber: sin fecha
  planificada no hay sesiones de manana. El recordatorio de entrenamiento pasa a
  enviarse **el dia en que arranca el planning**, resumiendo cuantas sesiones trae la
  semana (`correoDeSemanaNueva`). El aviso del dia de control no cambia: ese si
  depende de un dia real, el `dia_control_preferido` del cliente.

**Corregido (seguimiento del mismo cambio):**

- El script de verificacion seguia creando sesiones **con `fecha`** en el bloque de
  CU-06 por REST (solo se habian migrado los `insert` por psql): PostgREST
  respondia `PGRST204, no existe la columna 'fecha'` y se caia en cascada todo lo
  que colgaba de esa sesion. Ahora comprueba lo que toca: que `orden = 0` se
  rechaza, que el dia 1 se crea, que repetir numero da 409 y que la sesion **nace
  sin fecha de realizacion**.
- La comprobacion "y la sesion pierde su fecha" estaba **mal escrita, no el
  trigger**: borraba la serie de fuerza pero dejaba el cardio con sus minutos, asi
  que seguia habiendo algo registrado y la sesion conservaba la fecha con razon
  (el cliente si estuvo ese dia). Partida en dos: conserva la fecha mientras quede
  cardio, y la pierde cuando no queda nada.
- `scripts/probar_local.sh` acepta ahora `BASE_FUNCIONES` para llamar a las Edge
  Functions fuera de Kong. Por defecto no cambia nada.

**Pendiente / notas:**

- **Docker 29.1.2 no dejaba arrancar el contenedor del edge runtime** (`failed to
  copy edge runtime main service into container`) ni el de Studio
  (`mkdir /run/desktop/mnt/host/c: file exists`). Actualizar la CLI de Supabase
  de 2.118.0 a 2.119.0 **no lo arreglo**. Para no quedarme sin verificar nada se
  hizo un apano: `supabase start -x studio -x edge-runtime` mas
  `scripts/servir_funciones_host.sh`, que sirve las tres funciones con el Deno
  del host, y `BASE_FUNCIONES` en `probar_local.sh` para apuntarlas ahi.
  **Despues el contenedor acabo arrancando solo** (se redescargo la imagen) y el
  script volvio a pasar entero por Kong, asi que el apano queda guardado por si
  reaparece, documentado como trampa 23. Con el o sin el, la verificacion de las
  sesiones numeradas esta hecha.
- Sigue sin confirmarse en navegador el test de conversion de imagenes:
  `flutter test --platform chrome` no llega a cargar la suite ("Connection closed
  before test suite loaded"). En VM pasa.

**Hecho (foto del ejercicio en la planificacion y reordenado por arrastre):**

- **La foto del ejercicio ya se ve en la planificacion.** No era que no cargara:
  aquella pantalla ni siquiera pedia su URL, porque tenia su propia copia del
  hueco gris de cuando el ejercicio no tenia imagen. Igual que el panel desde el
  que se anaden ejercicios y la tarjeta de sesion.
  - Ahora hay **un solo widget**, `MiniaturaEjercicio`, que usan la biblioteca,
    la planificacion del entrenador, el panel de anadir, la tarjeta de sesion y
    el registro del cliente. Tener cuatro copias de lo mismo es exactamente lo
    que hizo que anadir la imagen a la entidad no llegara a tres de ellas.
  - Donde no hay foto se queda el hueco con el icono de su tipo (mancuerna o
    carrera), y si la imagen no carga se cae al mismo hueco en vez de dejar un
    roto.
  - En "Mi planning" del cliente **no** se ha tocado el circulo de la izquierda:
    ahi ese icono no es un hueco de foto, dice si la sesion esta hecha, en curso
    o pendiente. Si se quiere la foto tambien ahi, habria que decidir donde va
    ese estado.

- **Bloques y ejercicios se reordenan arrastrandolos** (CU-11, CU-12), con el
  asa a la izquierda. En las dos pantallas que los pintan: el editor del
  entrenador y el detalle del planning.
  - Migracion `20261004110000_reordenar_bloques_y_ejercicios.sql`, consultada
    antes: dos funciones que **renumeran el conjunto entero** en una
    transaccion. Con `update` sueltos no se puede: `(sesion_id, orden)` y
    `(bloque_id, orden)` son indices unicos y se comprueban fila a fila, asi que
    toda renumeracion pasa por un estado con dos filas en la misma posicion. Las
    funciones restan un millon a todos los ordenes (desplazamiento uniforme, la
    unicidad se mantiene) y luego escriben los definitivos.
  - Reciben la lista completa de ids en el orden que debe quedar, y rechazan una
    lista incompleta o con repetidos. La app valida lo mismo antes de llamar,
    para no gastar un viaje cuando la pantalla ha perdido el hilo.
  - Se uso `onReorderItem` y no `onReorder`, que esta deprecado: el nuevo ya
    corrige el indice de destino. Con el viejo habria que restar uno al
    arrastrar hacia abajo, que es el fallo clasico de dejar el elemento donde
    estaba.

**Corregido:**

- **El cliente podia reordenar los ejercicios de su propio planning.** Lo saco
  la comprobacion nueva del script: 204 donde esperaba 403. La causa es la "nota
  de seguridad conocida" del esquema: el cliente tiene politica de `update`
  sobre `ejercicios_planificados` para registrar sus minutos de cardio (CU-20),
  y una politica RLS **no puede limitar que columnas se tocan**. Con los bloques
  no pasaba, porque ahi no tiene ninguna politica de escritura.
  - Arreglado comprobando `es_entrenador()` dentro de las dos funciones, ademas
    de apoyarse en RLS. La nota sigue abierta para quien haga un `PATCH` directo
    a la tabla, que es lo que ya habia antes de esto.
  - Las funciones miran ademas `row_count` del primer `update`: con RLS, un
    `update` prohibido no da error, simplemente no toca filas, y sin eso la
    funcion se iria sin excepcion y sin haber reordenado nada.
- `_mensajeDeDuplicado` seguia buscando el indice `sesiones_planning_fecha_unico`,
  que ya no existe desde el cambio de esta manana. Ahora mira el de `orden`.

**Pendiente / notas:**

- `./scripts/probar_local.sh` da **177/177** (11 comprobaciones nuevas:
  intercambio de bloques, listas invalidas, el rechazo al cliente y la vuelta de
  los ejercicios). `flutter test` **337**, con tests nuevos del arrastre (que el
  asa solo la ve el entrenador, y que soltar manda los indices correctos), de
  `reordenarLista` y de que la miniatura pide la URL de la foto.
- Queda decidir si la foto debe verse tambien en la lista de sesiones de "Mi
  planning" del cliente, y donde iria entonces el estado de la sesion.

### 2026-10-05

**Hecho:**

- **Al planificar, el entrenador ve lo que el cliente hizo la ultima vez.** En la
  fila de cada ejercicio, las series quedan a la izquierda (lo que escribe) y a la
  derecha lo realizado, con su fecha. Es como trabaja de verdad: no planifica
  desde cero, mira como le fue al cliente y ajusta a partir de ahi. Antes tenia
  que abrir el planning de la semana pasada en otra pantalla.
- **De donde sale el dato**, en este orden: el Dia N del planning inmediatamente
  anterior (cruzando por `ejercicio_id`, no por posicion, porque el ejercicio
  puede haberse movido de bloque) y, para lo que no este ahi, el ultimo registro
  que haya de ese ejercicio. El segundo caso se marca como "Ultima vez · 16/09"
  en vez de "Semana pasada", porque no es lo mismo planificar sobre lo de hace
  siete dias que sobre algo de hace un mes.
- **Sin SQL nuevo**: la jerarquia completa ya trae `series_realizadas` desde la
  fase 5, y el historico sale de `vista_progreso_ejercicios`, la misma vista de
  CU-21, con un metodo nuevo en el repositorio de progreso
  (`ultimoDeCadaEjercicio`) que pide varios ejercicios de una vez en lugar de uno
  por viaje.
- **Boton de copiar** por ejercicio: vuelca kg, reps y RIR de lo realizado a los
  campos de lo planificado, listo para retocar. **No guarda**: queda como cambio
  pendiente del boton de siempre. Si el cliente hizo cuatro series donde habia
  tres planificadas, se copian las cuatro, y las series se renumeran del 1 por si
  el registro tuviera huecos.
- En Cardio no hay boton: los minutos no se editan en esta pantalla, se cambian
  en el formulario del ejercicio. Si se ensena lo que hizo ("Semana pasada: 28
  min").
- Con poco ancho las dos mitades no caben, asi que lo realizado pasa debajo, una
  linea por serie, con el mismo boton de copiar. Umbral de 560 px medidos con
  `LayoutBuilder` sobre el espacio real, no sobre el tamano de pantalla.

**Pendiente / notas:**

- La referencia **no bloquea la pantalla**: si la consulta falla o tarda, la
  planificacion funciona igual sin ella. Es una ayuda; quedarse sin poder
  planificar porque no carga el historico seria peor que no verla.
- Verificado en el navegador contra Supabase local, con tres semanas de datos
  sembrados: Press banca ensena "Semana pasada · 30/09" con sus tres series
  (incluida la cuarta fila de la serie que el cliente hizo de mas, sin campo
  enfrente), Dominadas cae a "Ultima vez · 16/09", y el Cardio ensena sus
  minutos. Copiado y guardado comprobados en Postgres.
- `flutter test` **353** (16 nuevos: eleccion del planning anterior, cruce por
  ejercicio, agrupado del historico, orden de las dos fuentes y conversion del
  boton de copiar). `dart analyze --fatal-infos` limpio y `flutter build web`
  compila. `probar_local.sh` no cambia: no hay SQL nuevo que comprobar.
- Esto es solo el editor del entrenador. La vista de detalle del planning
  (`pantalla_planning.dart`) no lo ensena, porque ahi no se editan series; si se
  quiere tambien alli, hay que decidir como.

**Hecho (datos de demostracion):**

- `supabase/seed_demo.sql`, cargado por `supabase db reset` junto al seed de
  siempre (listado en `[db.seed] sql_paths`). Trae 15 ejercicios de biblioteca
  con grupo muscular, equipamiento y descripcion de verdad, y un cliente de
  demostracion, **Ana Demo** (`demo@local.test`), con tres semanas: dos
  archivadas con sus resultados registrados y la de esta semana activa y sin
  registrar, mas medidas y check-in para que el progreso no salga vacio.
- Esta montado para que aparezcan los casos que cuesta reproducir a mano: una
  sesion dejada a medias, un ejercicio que esta esta semana pero no la pasada
  (asi se ve la referencia "Ultima vez · dd/mm" y no solo "Semana pasada"),
  cardio con minutos realizados, y carga que sube de una semana a otra.
- **Cliente distinto de `cliente@local.test`** a proposito: `probar_local.sh` usa
  ese cliente y le crea un planning activo de la semana en curso. Si el seed le
  dejara uno, el indice de "un planning activo por cliente y semana" tumbaria ese
  bloque entero con un 409 antes de empezar.

**Corregido:**

- La comprobacion 'el entrenador ve todas las fichas' del script esperaba **1**
  cliente fijo, asi que fallaba en cuanto el seed traia otro. Ahora compara
  contra el total real de la tabla, que es lo que decia su nombre: lo que se
  verifica es que el entrenador los ve **todos**, no cuantos hay. Con los datos
  de demostracion cargados, el script sigue en **177/177**.

**Pendiente / notas:**

- El seed deja el video de ejemplo de un ejercicio apuntando a un corto libre de
  YouTube, solo para probar que el reproductor incrustado tira. Hay que
  sustituirlo por los videos reales de Aimar cuando los haya.

**Hecho (pipeline de despliegue):**

- Job `desplegar` en `.github/workflows/ci.yml`: aplica migraciones
  (`supabase db push --linked`) y publica las Edge Functions
  (`supabase functions deploy --use-api`, que empaqueta en el servidor y no
  necesita Docker en el runner) en cada push a `dev` y a `main`.
- **Depende de que CI este en verde** (`needs: [flutter, edge-functions]`):
  desplegar un esquema cuyo codigo no compila o no pasa los tests es justo lo que
  el pipeline existe para impedir.
- El proyecto destino lo decide el **Environment** de GitHub (`desarrollo` para
  `dev`, `produccion` para `main`), no un `if` con dos juegos de secretos: asi la
  receta es una sola y a `produccion` se le pueden exigir revisores desde
  Settings. Hoy solo existe el proyecto de dev (`app-aimar-trainer-dev`), asi que
  el entorno de produccion se queda sin secretos y el job **se salta solo** en vez
  de dejar `main` en rojo.
- `cancel-in-progress` pasa a ser solo para los PR. Antes cancelaba cualquier
  ejecucion anterior de la misma referencia; con el despliegue dentro, eso podria
  cortar un `db push` por la mitad y dejar el esquema en un estado que nadie ha
  probado.
- La version de la CLI va fijada (2.119.0), no `latest`: lo que se aplica a una
  base de datos no debe cambiar porque salga una version nueva de una herramienta.

**Pendiente / notas:**

- **No se ha desplegado nada todavia**: falta crear los tres secretos del
  entorno `desarrollo` (`SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`,
  `SUPABASE_DB_PASSWORD`). Hasta entonces el job se salta.
- El pipeline **no** lleva los secretos de Vault del job de recordatorios ni los
  de las Edge Functions. Son valores, no codigo, y meterlos en el workflow los
  pasearia por un log de CI. Se ponen una vez a mano; los pasos estan en
  `estado-actual.md`. Alternativa sin decidir: la seccion `[db.vault]` de
  `config.toml`, que `db push` aplica antes de las migraciones.
- Ojo con el primer `db push` a la nube: la migracion del job de recordatorios
  crea `pg_cron` y `pg_net`. En Supabase cloud son extensiones permitidas, pero
  si el proyecto las tuviera bloqueadas habria que habilitarlas antes desde el
  panel.

- **Correccion del reparto de ramas, el mismo dia:** el proyecto de Supabase ya
  tenia la **integracion de GitHub conectada a `main`** (branching con
  `git_branch: main`, visto con `supabase branches list`), asi que ya desplegaba
  solo al hacer push a esa rama. El primer reparto que escribi (`dev` al proyecto
  actual, `main` a un hipotetico produccion) no encajaba con eso y ademas habria
  dejado dos sistemas escribiendo en la misma base.
  - Ahora el Environment **se llama como la rama** (`main`, `dev`): los secretos
    del proyecto actual van en `main`, y `dev` queda preparado por si algun dia
    hay un segundo proyecto.
  - Decision tomada: **lo lleva Actions y se desconecta la integracion del
    panel**. El motivo es que la integracion aplica las migraciones sin mirar el
    CI: con los tests en rojo desplegaba igual.

**Corregido (el CI estaba en rojo):**

- **`deno check` fallaba en `crear-cliente`** con `TS2353: 'data' does not exist
  in type 'GenerateInviteOrMagiclinkParams'`. No tenia nada que ver con el
  despliegue ni con las Edge Functions del proyecto en la nube: era el job de
  comprobacion de tipos.
  - Causa: `deno.json` pedia `npm:@supabase/supabase-js@2`, **sin version fija**,
    asi que el CI resolvia una version mas nueva que cuando se escribio aquello.
    `auth-js` movio `data` dentro de `options`.
  - El codigo **funcionaba** igual con `data` en la raiz, porque la libreria monta
    el cuerpo con `{...resto, ...options}`. Era un fallo de tipos, no de
    comportamiento; por eso el script local nunca lo vio.
  - Arreglado moviendo `data` dentro de `options` y **fijando la version**
    (2.117.2), como ya estaba `web-push`. Comprobado que la bandera sigue
    llegando: el cliente que crea la funcion tiene
    `{"debe_fijar_contrasena": true}` en `raw_user_meta_data`.
- **`enviar-recordatorios` no pasaba por `deno check`**: se anadio en la fase 6 y
  el paso del CI se quedo con las dos funciones antiguas. Ahora comprueba las
  tres (pasa limpia).

**Pendiente / notas:**

- Verificado en local con las Edge Functions reales servidas en Docker:
  `./scripts/probar_local.sh` **177/177**, y `deno fmt`, `deno lint` y
  `deno check` de las tres funciones en verde.
- El job de despliegue no llego a ejecutarse en esas ejecuciones rojas, que es lo
  que se buscaba con `needs`: si los tipos no compilan, no se toca ninguna base
  de datos.

**Hecho (Vercel):**

- `vercel.json` con la receta de despliegue de la web: descarga el SDK de Flutter
  3.47.5 (el mismo del CI y el de local, y se comprobo que el tar de esa version
  existe), hace `pub get`, compila en release y publica `build/web`.
- Los cuatro `--dart-define` salen de **variables de entorno del proyecto en
  Vercel**, no de `config/prod.json`, que no esta en git. El comando falla pronto
  y con mensaje claro si faltan `SUPABASE_URL` o `SUPABASE_PUBLISHABLE_KEY`, en
  vez de compilar una app que arranca sin saber a donde conectarse.
- Cabeceras de cache: `index.html`, `version.json` y los **dos** service workers
  (`flutter_service_worker.js` y `push_sw.js`) sin cachear; `canvaskit/` y
  `assets/` un ano e inmutables. Un service worker cacheado es la razon clasica de
  "he desplegado y sigo viendo lo viejo".
- No hacen falta *rewrites* de SPA: el enrutador usa rutas con `#`, asi que el
  servidor nunca ve rutas que no existan como fichero.

**Pendiente / notas:**

- `Service-Worker-Allowed` en `/push/` no hace falta y se quito: el ambito
  (`push/`) es mas restrictivo que la ubicacion del script (`/push_sw.js`), y esa
  cabecera solo se necesita para lo contrario.
- Cuando haya dominio hay que apuntarlo en `APP_BASE_URL` (secreto de las Edge
  Functions) y en las *Redirect URLs* de Auth, o los enlaces de invitacion y de
  recuperacion de contrasena no volveran a la app.

