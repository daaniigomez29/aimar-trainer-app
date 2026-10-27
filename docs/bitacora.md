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

**Corregido (Vercel rechazaba el despliegue):**

- `The vercel.json schema validation failed: buildCommand should NOT be longer
  than 256 characters`. El comando de compilar, con las comprobaciones y los
  cuatro `--dart-define`, se iba a 399 caracteres.
  - Movido a `scripts/vercel_build.sh` (y de paso el de instalar a
    `scripts/vercel_install.sh`, que con una linea mas tambien se habria pasado).
    En `vercel.json` quedan dos ordenes de menos de 30 caracteres.
- El script de instalacion anade `git config --global --add safe.directory` sobre
  la carpeta del SDK: el SDK es un repositorio git y lo usa para saber su
  version, asi que si el dueno de la carpeta no coincide con el usuario del build,
  git responde "detected dubious ownership" y `flutter` no arranca. Salio al
  reproducirlo en Docker.

**Pendiente / notas:**

- **Reproducido el despliegue entero en un contenedor Debian limpio**, que es lo
  mas parecido al runner de Vercel que se puede montar aqui: descarga del SDK,
  `pub get`, el fallo con mensaje legible cuando faltan las variables, y el build
  completo generando `build/web`. Lo unico que no se puede comprobar desde fuera
  es que el runtime de Vercel traiga `xz` para `tar -xJ`; si fallara ahi, la
  alternativa es clonar el SDK con git, que seguro esta disponible.

### 2026-10-06

**Corregido:**

- **Ortografía de todos los textos que ve el usuario.** Estaban escritos sin
  tildes y con `n` en lugar de `ñ`: "Anadir", "Dia 1", "sesion", "contrasena",
  "Configuracion", "video"… Corregidos **169 literales** en `lib/` y 111 en los
  tests, que buscaban esos mismos textos y habrían empezado a fallar.
- Se corrigió solo el **interior de los literales**, nunca identificadores: las
  claves de widget (`Key('anadir_bloque_…')`), los nombres de columna y los
  `viewType` siguen igual, porque cambiarlos rompería claves de test y consultas.
  La regla: un literal sin espacios y en minúscula se deja tal cual.
- **Dos trampas del arreglo automático**, vistas al revisar el primer intento (se
  revirtió entero y se rehízo):
  - `'$titulo'` dentro de un literal es una **interpolación**, no texto: al
    "corregirla" pasaba a `$título`, una variable que no existe. Ahora las
    interpolaciones se protegen antes de tocar nada.
  - `'video-ejemplo-${url.hashCode}'` es el identificador de una vista de
    plataforma, no una etiqueta: también quedaba fuera.
- Las palabras ambiguas se revisaron **a mano**, una por una: "La biblioteca
  esta vacía" → "está"; "Como se ejecuta" y "Como te avisamos" → "Cómo" (son
  interrogativas indirectas). En cambio "Como máximo", "esta semana" y "mayor
  que cero" estaban bien y se dejaron.
- **Los correos** (invitación, semana nueva y control semanal) también se
  corrigieron: los lee el cliente igual que la pantalla.
- **La PWA seguía con los valores por defecto de Flutter**: el `manifest.json` y
  el `index.html` decían `aimar_trainer_app` y "A new Flutter project", que es lo
  que se ve en la pestaña del navegador y al instalar la aplicación. Ahora es
  "Aimar Trainer" con su descripción, y los colores del tema en vez del azul de
  la plantilla.

**Pendiente / notas:**

- Verificado en la app compilada: acceso ("Contraseña"), planificación
  ("Planificación", "Día 1 · Empuje", "Añadir ejercicio") y biblioteca
  ("17 ejercicios · 1 con vídeo de ejemplo"). `dart analyze --fatal-infos`
  limpio y `flutter test` **353** en verde.
- **Los comentarios del código y la documentación siguen sin tildes**. No se han
  tocado a propósito: es un cambio enorme y ruidoso que conviene decidir aparte,
  no mezclado con el de la interfaz.

**Corregido (CORS al dar de baja en produccion):**

- El sintoma era `preflight ... does not have HTTP ok status` desde el dominio de
  Vercel. **La causa no era el CORS**: `crear-cliente` y `dar-de-baja-cliente`
  **no estan desplegadas** en la nube (comprobado con `supabase functions list`:
  solo esta `enviar-recordatorios`). El preflight recibe un 404 y el navegador lo
  cuenta como fallo de CORS.
- Aun asi, en cuanto se desplieguen se habrian encontrado con el **segundo**
  problema: `verify_jwt` estaba activo para esas dos funciones, y el preflight no
  lleva `Authorization`, asi que la plataforma lo rechaza con 401 antes de llegar
  al codigo. Añadido `verify_jwt = false` en `config.toml` para ambas. No abre
  nada: `autorizarGestorDeClientes` valida el JWT y el rol, que es mas de lo que
  comprueba la plataforma.
- **CORS con varios origenes**, como se pidio: `APP_BASE_URL` acepta una lista
  separada por comas (Vercel y `aimartrainer.es`). `Access-Control-Allow-Origin`
  solo admite un valor, nunca una lista, asi que se mira el `Origin` de cada
  peticion y se devuelve ese, con `Vary: Origin` para que ninguna cache sirva a un
  dominio la respuesta del otro.
- Las cabeceras se ponen ahora en **un solo sitio**, `servirConCors`, que envuelve
  el manejador de las tres funciones. Antes cada respuesta las llevaba pegadas, y
  el origen permitido depende de cada peticion: con treinta llamadas a
  `respuestaJson`/`respuestaError` habria sido pasarles el `Request` a todas.
- **Efecto colateral cazado a tiempo**: `APP_BASE_URL` tambien es el enlace de los
  correos de invitacion y de recordatorio. Con una lista separada por comas esos
  enlaces habrian quedado rotos, asi que ahora salen de `urlBaseApp()`, que
  devuelve el primero. Comprobado en Mailpit: los correos llevan
  `http://127.0.0.1:54330/#/cliente`, no la lista.

**Pendiente / notas:**

- Verificado sirviendo las funciones de verdad: el preflight responde **204** y
  cada origen permitido recibe el suyo; uno desconocido recibe otro distinto y el
  navegador lo bloquearia. `./scripts/probar_local.sh` **176/177** (el que falla
  es el salto de pg_cron por Kong, porque el contenedor del edge runtime volvio a
  no arrancar: trampa 23).
- **Lo que falta para que funcione en produccion** no es codigo: desplegar las dos
  funciones y poner `APP_BASE_URL` con los dos dominios.

**Corregido (tres bugs vistos en producción):**

- **El "Deshacer" del aviso de baja no hacía nada.** Desde el listado sí
  funcionaba; desde la ficha del ejercicio no, y esa es la diferencia: la ficha
  hace `pop` al dar de baja, así que cuando el usuario pulsaba, el
  `BuildContext` con el que se había lanzado el aviso ya estaba muerto y la
  reactivación salía por un `if (!context.mounted) return` **sin decir nada**.
  - Arreglado capturando, con la pantalla aún viva, el `ScaffoldMessengerState`
    (vive en el `MaterialApp`) y el `ProviderContainer` (vive con la aplicación).
    El botón ya no depende del `context` ni del `ref` de quien lo lanzó.
  - Test nuevo que reproduce justo eso: lanza la baja desde una pantalla que se
    cierra a continuación y comprueba que el botón sigue reactivando.
- **Los avisos tardaban cuatro segundos** (el valor por defecto de Flutter) y uno
  llegaba a ocho. Ahora **tres**, desde `Avisos.duracion`, en los 30 `SnackBar`
  de la aplicación. El tema no sirve para esto: `SnackBarThemeData` no tiene
  duración, de ahí la clase nueva en `core/presentacion/widgets/avisos.dart`.
  - Los que ofrecen **Deshacer** duran seis: en tres segundos no da tiempo a leer
    y decidir, y al irse el aviso se va la única forma de echar atrás.
- **El filtro "Dados de baja" mostraba todo.** Se llamaba `incluirEliminados` y
  hacía exactamente eso, incluirlos **además** de los activos. Pasa a
  `soloEliminados` (y `soloBajas` en clientes): con el chip puesto se ven las
  bajas y nada más; sin él, solo los activos. Mismo arreglo en las dos pantallas.

**Hecho (segunda pasada de ortografía):**

- Repasando la aplicación aparecieron más faltas que la primera pasada no cubría:
  futuros (`se dara`, `podra`, `seguira`, `conservaran`), infinitivos con
  pronombre (`anadirse`), `todavia`, `ningun`, `busqueda`, `cuadriceps` y los
  `esta` que son el verbo `está`.
- Para las terminaciones se añadió una **regla general**: toda palabra acabada en
  `-cion`/`-sion` lleva tilde (`acción`, `dirección`, `versión`), y en plural no
  (`acciones`), que es lo que cubre los casos que queden sin enumerar.
- Los `esta` se revisaron **uno a uno**: "esta semana" es demostrativo y no lleva
  tilde, "la biblioteca está vacía" sí. Un reemplazo automático se habría
  equivocado en la mitad.

**Pendiente / notas:**

- Verificado en la aplicación compilada: el filtro de bajas deja **1 ejercicio**
  (solo el dado de baja) y **ningún** cliente cuando no hay bajas; el "Deshacer"
  reactiva y la lista se actualiza. `flutter test` **355**, `dart analyze
  --fatal-infos` limpio.
- Al arreglar la duración, un primer script automático destrozó once ficheros
  (duplicó cada `SnackBar` y metió `duration:` en `showSnackBar`). Se revirtieron
  y se rehízo con un reemplazo simple; conviene recordar que `showSnackBar(`
  contiene `SnackBar(` como subcadena, que fue justo el fallo.

**Corregido (el atrás del navegador no volvía donde tocaba):**

- Sintoma: entrar en un ejercicio o en la ficha de un cliente y pulsar atras
  llevaba a la planificacion o a los ajustes, segun donde hubieras estado antes.
- Causa: las pantallas de detalle y los formularios se abrian con
  `Navigator.push` imperativo (21 sitios, 11 ficheros, 4 features). En web eso
  **no deja entrada en el historial**, asi que el atras del navegador retrocedia
  a la ultima ruta de go_router. La flecha de la cabecera si funcionaba, por eso
  solo fallaba el del navegador y el gesto atras del movil.
- Ahora **todo son rutas**: `/entrenador/ejercicios/:id`,
  `/entrenador/clientes/:id` y lo que cuelga de la ficha (plannings, progreso,
  control), el planning del cliente con su registro de sesion y de ejercicio, y
  el formulario de un ejercicio dentro de un bloque.
- **Hubo que cambiar `context.push` por `context.go`.** Con `push` la URL del
  navegador **no cambia**, asi que el refactor no habria arreglado nada: se vio
  probando la app ya convertida y comprobando `window.location.hash`, que seguia
  en la ruta anterior. Ninguna de esas llamadas usaba el valor devuelto, asi que
  el cambio fue directo.
- Las pantallas que recibian objetos (los dos formularios, el formulario de
  ejercicio planificado y el registro de ejercicio) ahora los resuelven por `id`:
  los dos primeros con sus providers, y los otros con `ResolverDelPlanning`, que
  carga el planning y saca de el el bloque, la sesion o el ejercicio.
- `pantalla_planning` sirve a los dos roles y el planning cuelga de sitios
  distintos, asi que construye las rutas de lo que abre a partir de
  `GoRouterState.of(context).uri.path`, la ruta por la que se ha llegado.

**Pendiente / notas:**

- Verificado en el navegador: desde el detalle de un ejercicio, el atras vuelve a
  la **Biblioteca**; y entrando directamente por
  `#/entrenador/clientes/<id>` se pinta la ficha entera, que es lo que antes era
  imposible (recargar te echaba a la planificacion).
- Los tests de pantalla que navegan necesitan ahora un router: se anade
  `test/ayudas/app_con_rutas.dart`. **Las rutas del test deben ir anidadas igual
  que en la app**: con rutas hermanas, cerrar un formulario vacia la pila y el
  test falla por algo que no pasa en la aplicacion.
- `flutter test` **356**, `dart analyze --fatal-infos` limpio, `flutter build
  web` compila.


**Corregido (no se podían añadir ni quitar series a un ejercicio ya añadido):**

- Sintoma: en la pantalla de planificacion del entrenador, la cuadricula de
  series deja escribir kg, reps y RIR, pero el numero de series queda fijado al
  anadir el ejercicio. Si al final sobraba una serie, no habia forma de quitarla.
- Causa: el formulario que si sabe hacerlo (`PantallaFormularioEjercicioPlanificado`,
  CU-08 y CU-12) ya aceptaba un ejercicio previo y su ruta de edicion existia,
  pero **a esa pantalla no se llegaba desde la planificacion**: la fila del
  ejercicio solo tenia la X de quitarlo del bloque. En Cardio era aun mas visible,
  porque los minutos tampoco se editan en la cuadricula.
- Ahora cada ejercicio lleva un boton de editar a la izquierda de la X, que abre
  ese mismo formulario con sus datos (`Rutas.editarEjercicioDelBloque`). No hay
  logica nueva de guardado: es la de siempre.
- **Anadir y editar han dejado de estar anidadas**: la ruta de editar colgaba de
  la de anadir, asi que al guardar (o al pulsar atras) el entrenador aparecia en
  un formulario de "Anadir ejercicio" vacio en vez de volver al planning. Ahora
  son rutas hermanas, en los tres sitios donde se declaran.
- `_EjercicioEditable` recarga sus filas con `didUpdateWidget` cuando las series
  cambian por detras, y avisa al padre para que **olvide lo pendiente** de ese
  ejercicio. Sin eso, al volver del formulario la cuadricula seguia enseñando lo
  de antes y "Guardar cambios" lo habria escrito encima de lo recien guardado.

**Pendiente / notas:**

- Verificado en el navegador contra Supabase local: desde el planning se edita
  "Sentadilla trasera", se le anade una serie, se guarda (vuelve a `#/entrenador`)
  y la cuadricula pasa a dos series; al quitarla, vuelve a una.
- `flutter test` **359** (tres nuevos sobre el formulario en modo edicion),
  `dart analyze --fatal-infos` limpio.

### 2026-10-07

**Hecho:**

- En el formulario de anadir y editar un ejercicio de un bloque, la fila de cada
  serie pone **primero el peso y luego las repeticiones**. Es el orden que ya
  tenian la cuadricula de la planificacion (Kg · Reps · RIR) y el registro del
  cliente; el formulario era el unico sitio que lo llevaba al reves.

**Hecho (calendario por semanas en la planificación):**

- "Semana del 5-11 oct" es ahora un boton: abre un calendario y **se queda con la
  semana del dia que se toque**. Pulsar el miercoles 14 lleva a la semana del 12
  al 18. Evita ir a una semana lejana a base de pulsar la flecha veinte veces.
- La semana de lunes a domingo pasa a ser un concepto del dominio
  (`domain/semana.dart`). Estaba repetido en la navegacion y en el formulario,
  cada uno con su copia del calculo del lunes.
- La etiqueta distingue las semanas a caballo entre dos meses: "28 sep - 4 oct"
  en vez de un solo nombre de mes, que con el calendario se ve mucho mas.

**Corregido (crear planning proponia la semana equivocada):**

- Sintoma: navegar a la semana del 19 al 25 para adelantar trabajo y, al pulsar
  "Crear la semana", encontrarse la del 4 al 11, la de hoy.
- Causa: el dialogo calculaba el lunes **de hoy** por su cuenta, sin enterarse de
  por que semana iba la pantalla. Ahora la recibe (`pedirDatosPlanning(semana:)`).
- Su calendario tambien ajusta a la semana: elegir el jueves 22 deja
  "Del 19/10 al 25/10".

**Corregido (el cliente seguia viendo un planning borrado):**

- Sintoma: el entrenador eliminaba un planning y el cliente lo seguia viendo
  hasta cambiar de pestana o pulsar "recargar".
- Causa: son dos sesiones distintas. La app del cliente tenia la lista cacheada y
  nada le decia que habia cambiado.
- Dos vias, porque ninguna cubre sola todos los casos:
  - **Realtime** sobre `plannings_semanales` (migracion
    `20261007090000_realtime_plannings.sql`): el aviso llega al momento aunque el
    cliente este con la pantalla delante.
  - **Al recuperar el foco** (`AppLifecycleListener`): cubre el socket caido y,
    ademas, los cambios de **dentro** del planning, que no van por realtime.
- `replica identity full` no es decoracion: por defecto el WAL de un DELETE solo
  lleva la clave primaria, asi que Realtime no puede evaluar ni el filtro de la
  suscripcion ni la RLS del que escucha, y el borrado —justo el caso del fallo—
  no le llegaria a nadie.

**Pendiente / notas:**

- Verificado contra Supabase local: con la cliente de demo en pantalla, un
  `delete` en la base de datos hace desaparecer el planning **sin tocar nada**; y
  simulando que la pestana se oculta y vuelve, se ve la segunda peticion de la
  lista en la red.
- Los dos calendarios salen **en ingles** ("Mon, Oct 5", "October 2026"): la app
  no tiene configurado `flutter_localizations` ni `locale`. Es anterior a este
  cambio, pero ahora se ve mas. Arreglarlo es anadir esa dependencia del SDK.
- `.claude/launch.json` tiene una segunda entrada, `aimar-verificacion` (puerto
  54331), para poder levantar la app sin pisar la sesion de depuracion de VS Code
  que usa el 54330.
- `flutter test` **370**, `dart analyze --fatal-infos` limpio.

**Corregido (el histórico del entrenador no se enteraba de los borrados):**

- Sintoma: eliminar el planning de la semana en curso y, al volver al historico
  del cliente, seguir viendolo hasta pulsar "recargar".
- Causa: la invalidacion de las listas estaba **en cada pantalla**, y a esta se
  le habia olvidado. El controlador solo recargaba el planning concreto
  (`planningCompletoProvider`), que al borrarlo ya no existe.
- Ahora lo hace el controlador: `_ejecutar(..., recargarListas: true)` en crear,
  editar, archivar, reactivar y eliminar planning, que son las operaciones que
  cambian **que plannings hay**. Lo de dentro de un planning (sesiones, bloques,
  ejercicios) no las toca. Se han quitado las invalidaciones sueltas de las
  pantallas, que ahora sobran.

**Hecho (interfaz de Material en español):**

- Se anade `flutter_localizations` (SDK) y la `MaterialApp` fija
  `locale: Locale('es')` con los tres delegados globales. Los `DatePicker`
  salian en ingles ("Mon, Oct 5", "October 2026") dentro de una interfaz que
  esta entera en espanol.
- Efecto secundario que viene bien: en espanol **la semana empieza en lunes**
  (L M X J V S D), asi que cada fila del calendario es una semana. Justo lo que
  necesita un selector que elige semanas.
- No se negocia con el idioma del sistema: la app es solo en espanol.

**Pendiente / notas:**

- Verificado en el navegador: eliminando el planning del 05/10 de Ana Demo, el
  historico vuelve con solo los dos archivados **sin tocar recargar**; y los dos
  calendarios salen en espanol.
- `flutter test` **374**, `dart analyze --fatal-infos` limpio.

**Corregido (la flecha de "semana siguiente" se quedaba clavada):**

- Sintoma: desde la semana del 19-25 de octubre de 2026 la flecha derecha no
  avanzaba. Eligiendo a mano el 26 se podia seguir sin problema.
- Causa: **el cambio de hora**. El domingo 25 de octubre de 2026 Espania atrasa
  el reloj, asi que esa semana dura 169 horas. `lunes.add(Duration(days: 7))`
  suma 168 horas absolutas, no siete dias: desde el lunes 19 a las 00:00 caia en
  el **domingo 25 a las 23:00**, que al quedarnos con el dia pertenece a la misma
  semana. La flecha llamaba a `siguiente` y devolvia la semana en la que ya
  estabas.
- El test de regresion encontro ademas el caso simetrico, que no se habia
  reportado: en el cambio de marzo la flecha de **anterior** se saltaba una
  semana entera (de la del 30 de marzo se iba a la del 16, no a la del 23).
- Arreglado con aritmetica de calendario (`DateTime(ano, mes, dia + n)`), que
  normaliza dias fuera de rango y siempre cae a medianoche de la zona. Se aplica
  tambien a `Semana.de` y a `domingo`, que tenian la misma trampa latente.
- El test recorre **dos anios de semanas** comprobando que avanzar y retroceder
  son siempre siete dias de calendario y que todo lunes queda a medianoche. Asi
  da igual la zona horaria de quien ejecute los tests: el cambio de hora que
  tenga su zona cae dentro del recorrido.

**Pendiente / notas:**

- Esto valia para cualquier fecha, no solo para la navegacion: `Semana.de` se usa
  para emparejar el planning con la semana que se mira, y un lunes a las 23:00 en
  vez de a medianoche habria hecho que dos semanas iguales no se reconocieran.
- `flutter test` **375**, `dart analyze --fatal-infos` limpio.

**Hecho (el cliente navega por semanas, como el entrenador):**

- La pantalla de inicio del cliente lleva el mismo navegador de semanas con
  calendario. Antes solo veia la que tocaba hoy y el historico estaba escondido
  en otra pantalla.
- `NavegadorDeSemana` pasa a ser un widget compartido: "ir a una semana" es la
  misma operacion para los dos roles y no tiene por que comportarse distinto.
- Una semana sin planning lleva la misma cabecera y el mismo navegador, para que
  llegar a un hueco no sea un callejon sin salida.

**Hecho (el video del ejercicio deja de estorbar):**

- Fuera el enlace de YouTube en crudo: cuando el video se ve ahi mismo, el enlace
  no aporta y ensuciaba la ficha. Sigue estando para los videos que no se pueden
  incrustar, que es cuando si hace falta.
- **Ahora se puede desplazar la pantalla con el dedo sobre el video.** Un iframe
  se traga la rueda y el gesto, y Flutter desplaza escuchando esos eventos: si el
  iframe se los queda, no hay scroll y el usuario no entiende por que. El iframe
  nace con `pointer-events: none` y se activa al tocarlo.
- El aviso de "toca para activar" se pinta **en el DOM, no en Flutter**: una
  vista de plataforma va POR ENCIMA del lienzo, asi que el aviso de Flutter
  quedaba debajo del video y no se veia. El texto sigue viviendo en Dart y viaja
  como parametro.
- Tambien hubo que dejar inerte el `div` contenedor: con el a `auto` era el quien
  quedaba bajo el puntero en vez del lienzo.

**Corregido (terminar el ultimo ejercicio dejaba al cliente en la lista):**

- Ahora vuelve al planning (`/cliente`). Al acabar, lo que el cliente quiere ver
  es como queda su semana, no la lista de lo que acaba de completar.

**Corregido (faltas de ortografia en texto visible):**

- Repaso de todos los literales de interfaz, no solo los dos que se habian visto:
  "aun" por "aún" (tres sitios), "mas" por "más", "cuantas/cuantos" por
  "cuántas/cuántos", "esta" por "está", "se eliminara" por "se eliminará" (seis
  sitios), "registro" por "registró", "archivalo", "reactivalo", "dejalo",
  "permitelas", "volveras", "sueno" por "sueño", "electronico", "gestion",
  "tecnica", "validos", "anoto", "como" por "cómo" (dos sitios).
- Dos tests comprobaban el texto con la falta; se han actualizado.

**Pendiente / notas:**

- Verificado en el navegador: el navegador de semanas del cliente salta de la
  semana en curso a la anterior y pinta su planning; sobre el video, la rueda
  **mueve la pantalla** (el reproductor pasa de 384 px a 290 px de altura), el
  aviso se pinta encima del iframe y al tocarlo el reproductor queda interactivo.
- Lo que NO se ha podido comprobar en el navegador: que al volver a abrir una
  ficha cuyo video ya se activo el aviso vuelva a salir. El reinicio se hace en
  `initState` y en `dispose`, pero la pantalla se quedo cargando en la ultima
  prueba. Si alguna vez aparece el video ya activo, es ahi donde hay que mirar.
- `flutter test` **380**, `dart analyze --fatal-infos` limpio.

### 2026-10-08

**Corregido (las Edge Functions no llegaban a produccion):**

- Sintoma: en el proyecto de la nube solo existia `enviar-recordatorios`, con
  fecha del 4 de octubre. `crear-cliente` y `dar-de-baja-cliente` no es que se
  hubieran borrado: nunca habian llegado a desplegarse. De rebote, el error de
  CORS al dar de alta un cliente era en realidad un 404 de una funcion que no
  estaba.
- Causa: `supabase functions deploy --use-api` sube **solo los `.ts`** de cada
  funcion (se ve en el log: `Uploading asset ...index.ts`, `..._shared/*.ts`) y
  empaqueta en el servidor. `supabase/functions/deno.json` **no viaja**, asi que
  el bundler se encontraba un `@supabase/supabase-js` a secas que no podia
  resolver: 400, *Relative import path not prefixed with / or ./ or ../*.
- Por que no lo cazo el CI: `deno check` recibe la configuracion por
  `--config supabase/functions/deno.json`, asi que para el los nombres a secas
  se resuelven perfectamente. El tipo pasaba; el empaquetado del servidor no.
- Arreglo: `npm:@supabase/supabase-js@2.117.2` y `npm:web-push@3.6.7` completos
  en el `import`. El import map se queda vacio a proposito, para que nadie
  vuelva a usar un nombre a secas pensando que se resuelve.
- Efecto colateral: `deno lint` tiene una regla (`no-import-prefix`) que prohibe
  exactamente eso. Esta desactivada en `deno.json`, porque su premisa —que el
  import map llega siempre— no se cumple aqui.

**Pendiente / notas:**

- `deno fmt --check`, `deno lint` y `deno check` pasan los tres en local, que es
  lo mismo que corre el CI. La prueba definitiva es el despliegue: el
  empaquetado solo ocurre en el servidor de Supabase.
- El job `desplegar` solo corre si pasan `flutter` y `edge-functions`. Conviene
  mirar que la ejecucion de `main` llegue hasta el final, no solo que el entorno
  tenga los secretos.

**Hecho (la barra de navegacion ya no desaparece):**

- Pantallas de detalle, formularios y registro montaban un `Scaffold` pelado, asi
  que entrar en un ejercicio, en una ficha o en el registro de una sesion dejaba
  al usuario sin navegacion: solo podia salir con la flecha de atras.
- Nuevo andamio `PantallaConNavegacion`, que elige barra de cliente o de
  entrenador segun `rolActualProvider`. La pantalla solo dice **en que seccion
  esta** (`SeccionDeNavegacion`), no la ruta: una misma pantalla cuelga de
  destinos distintos segun quien mire (el planning de un cliente es "Mi planning"
  para el y "Clientes" para el entrenador).
- Se quedan sin barra solo las de autenticacion: sin sesion no hay a donde
  navegar.
- El CTA del registro de ejercicio pasa al hueco `ctaInferior` del andamio. Si se
  dejaba como `bottomNavigationBar` habria dos barras.

**Corregido (el atras no volvia de donde se venia):**

- Sintoma: desde el inicio del cliente se abre el ejercicio del dia y, al pulsar
  atras, aparecia la pantalla de **registrar sesion**, por la que no se habia
  pasado.
- Causa: con rutas anidadas, `context.go` a una ruta profunda monta la pila
  entera, asi que la flecha automatica de `AppBar` lleva al **padre de la ruta**,
  no al sitio anterior.
- Arreglo: quien navega deja dicho de donde viene (`Rutas.conVuelta`, que lo pone
  como `?volver=` en la URL) y `BotonAtras` lo respeta. Sin ese parametro se
  comporta como siempre, asi que las pantallas a las que solo se llega por su
  padre no cambian.
- Va en la URL y no en `extra` para que sobreviva a una recarga, que en web pasa
  constantemente. El origen se arrastra ademas al encadenar ejercicios: terminar
  el tercero y pulsar atras sigue llevando al inicio.

**Hecho (la descripcion del ejercicio es opcional):**

- Hay ejercicios que se explican solos y obligar a escribir algo solo conseguia
  rellenos. Vacia se guarda como cadena vacia, no `null`: la columna es
  `not null` y esto no merecia una migracion. La ficha oculta el apartado "Como
  se ejecuta" cuando no hay nada que contar.

**Pendiente / notas:**

- Los tests de pantalla necesitan ahora una sesion, porque el andamio pregunta el
  rol: se anade `test/ayudas/sesion_falsa.dart`. El helper recibe el contenedor
  ya construido en vez de la lista de overrides porque **el tipo `Override` de
  Riverpod 3 no es publico** y no se puede nombrar en una firma.
- Verificado en el navegador: abriendo un ejercicio desde el inicio del cliente,
  la URL lleva `?volver=/cliente`, la barra de navegacion esta en pantalla y la
  flecha de atras devuelve a `/cliente`. En la ficha de un ejercicio, la barra
  marca "Biblioteca".
- `flutter test` **381**, `dart analyze --fatal-infos` limpio.

**Pendiente / notas (traspaso de conversacion):**

- Lo que queda abierto esta recogido en `docs/estado-actual.md`, seccion
  "Pendientes abiertos": el peso por lado (propuesta hecha, faltan dos decisiones
  del entrenador), las guardas de `dar-de-baja-cliente` tras el baneo accidental,
  y el formato de `RESEND_FROM_EMAIL`.
- Todo lo de hoy esta **sin commitear**: los commits los hace el.

### 2026-10-09

**Hecho (taxonomia muscular de dos niveles, CU-02/CU-03/RF-02):**

- `grupo_muscular` era `text` libre y en el propio seed convivian "Piernas" e
  "Isquiotibiales", region y musculo al mismo nivel. Sin jerarquia no se podia
  filtrar "Pierna -> Gluteo", que es como busca el entrenador.
- Ahora son dos enums, `GrupoMuscular` (6) y `Musculo` (21, la lista que dio
  Aimar), y cada musculo sabe su grupo. El ejercicio guarda **musculo principal
  y secundarios**; el grupo **se deriva** del principal y solo se guarda a mano
  cuando no hay uno concreto (el cardio).
- Los tres campos son opcionales. Un `check` impide que convivan grupo y
  principal, y otro que el principal se repita entre los secundarios.
- Al filtrar, los secundarios **cuentan**, pero el orden los distingue: delante
  los que lo tienen como principal, detras los demas con la marca "secundario".
- La biblioteca estrena filtro de dos niveles (chips de grupo y, al elegir uno,
  sus musculos) y pestana "Sin clasificar". Los chips salen de lo que hay en la
  biblioteca, no de la taxonomia completa: un chip que no devuelve nada es
  ruido.
- El mismo filtro va en el panel de biblioteca de la planificacion, que comparte
  estado (`filtroBibliotecaProvider`). Es donde el entrenador busca de verdad,
  una vez por ejercicio de cada bloque.
- El formulario sustituye el campo de texto por grupo -> principal ->
  secundarios. Los secundarios se eligen de **toda** la taxonomia, no solo del
  grupo del principal: en un press de banca el principal es del pecho y los
  secundarios son deltoides y triceps.

**Hecho (tercer tipo de ejercicio: Fortalecimiento, para clientes lesionados):**

- Se planifica **con series**, igual que Fuerza: en `series_planificadas` las
  repeticiones son obligatorias pero el peso y el RIR ya eran nulables, que es
  justo lo que pide el trabajo con peso corporal o goma.
- Color propio (`Tokens.terciario`) e icono propio, y el selector de tipo pasa
  de `SegmentedButton` a chips: con tres opciones, "Fortalecimiento" no cabe a
  lo ancho de un movil y el boton segmentado no reparte en varias lineas.

**Corregido (un tipo nuevo habria roto la exclusion series/minutos en silencio):**

- Las dos comprobaciones de SQL preguntaban `if v_tipo = 'cardio'` y
  `if v_tipo = 'fuerza'`, sin rama por defecto. Con un tercer valor, el trigger
  le habria dejado tener **minutos y series a la vez** y la RPC de registro
  habria descartado `p_minutos` sin decir nada.
- En Dart era peor: `esCardio ? minutos : series` **compila sin una queja** y
  convierte Fortalecimiento en Fuerza sin que nadie lo decida. Eran 20 sitios en
  8 archivos.
- Arreglo: la pregunta ya no es el tipo sino el **modo de planificacion**
  (`planifica_con_minutos()` en SQL, `TipoEjercicio.modo` en Dart). Es `if/else`
  sin hueco, y un tipo nuevo que no pase por ahi **falla en voz alta** en vez de
  colarse por la rama de series. Se quitaron `esFuerza`/`esCardio` del enum a
  proposito, para que el compilador listara los 20 sitios.

**Corregido (el script de pruebas fallaba 6 comprobaciones a partir de medianoche):**

- `probar_local.sh` montaba el planning del recordatorio con `current_date`, que
  en el contenedor es **UTC**, mientras la funcion razona en `Europe/Madrid`.
  Entre las 00:00 y las 02:00 espanolas son dias distintos, asi que el aviso de
  sesion no encontraba planning. Es la trampa 22 otra vez, ahora dentro del
  script. Ya usa `(now() at time zone 'Europe/Madrid')::date` en los tres sitios.
- No tenia nada que ver con los cambios de hoy: se vio al ejecutarlo por primera
  vez despues de medianoche.

**Corregido (la ficha no ocultaba la descripcion vacia):**

- La entrada del 2026-10-08 decia que la ficha oculta "Como se ejecuta" cuando
  no hay descripcion, pero el apartado se pintaba siempre y dejaba el hueco. Ya
  va condicionado.

**Migraciones (tres, verificadas contra Supabase local):**

- `20261008090000_tipo_fortalecimiento.sql`: solo el `alter type ... add value`.
  Va sola a proposito, porque ese valor no puede usarse en la misma transaccion
  en que se anade.
- `20261008090100_taxonomia_muscular.sql`: los dos enums, las columnas nuevas,
  los dos `check` y el mapeo de lo que ya habia. `grupo_muscular` se
  **renombro** a `grupo_muscular_antiguo` en vez de convertir su tipo: un `using`
  con mapeo habria perdido en silencio los valores no contemplados. Lo que no
  mapea se queda sin clasificar a proposito, visible en su chip.
- `20261008090200_modo_planificacion.sql`: `planifica_con_minutos()` y el
  `create or replace` del trigger y de `registrar_resultado_ejercicio` (misma
  firma exacta, para reemplazarla en sitio y no crear una sobrecarga).

**Pendiente / notas:**

- `supabase db reset` aplica **22 migraciones** limpias,
  `./scripts/probar_local.sh` da **184/184** (7 comprobaciones nuevas:
  Fortalecimiento no se planifica con minutos, registra series, no registra
  minutos, los dos `check` de la biblioteca, un musculo inventado se rechaza y
  con principal no se admite grupo), `flutter test` **401**,
  `dart analyze --fatal-infos` limpio.
- **Sin comprobar en el navegador**: con la ventana de Claude oculta el
  navegador deja de servir `requestAnimationFrame`, y como Flutter procesa los
  eventos de puntero dentro del frame, el lienzo ni pinta ni reacciona (el texto
  si entra, porque va al `<input>` oculto del DOM, lo que despista). Queda ver
  los chips de dos niveles, el formulario con sus tres selectores y el chip del
  tipo nuevo. El servidor de verificacion esta levantado en el 54331.
- El seed trae los 15 ejercicios reclasificados y cuatro de fortalecimiento
  (puente de gluteo, rotacion externa con goma, elevacion de talones y Pallof
  press). Son datos de demostracion: si Aimar discrepa de alguna clasificacion,
  se corrige desde el formulario.
- `requirements.md` sigue diciendo "grupo muscular" en RF-02 y en la secuencia
  de CU-02; el ERS completo necesita el mismo retoque. No se ha tocado sin
  decidirlo.
- Todo sin commitear: los commits los hace el.
**Hecho (el filtro muscular, plegado, y donde de verdad hacia falta):**

- Los 21 musculos pintados de golpe eran otra lista interminable. Ahora van en
  una lista con **un desplegable por grupo**: solo se abre el que interesa.
  Mismo widget (`ListaMusculosPlegable`) para elegir los secundarios de un
  ejercicio y para filtrar al buscar uno; el widget no decide nada, recibe que
  esta marcado y avisa de cada pulsacion.
- El formulario de CU-08 tenia un `DropdownButtonFormField` con la biblioteca
  entera dentro. Ahora comparte con el panel lateral del planning el mismo
  buscador y el mismo filtro (`FiltroDeEjercicios`), con el filtro entero dentro
  de **otro** desplegable: de partida solo se ve el buscador y una linea que
  dice por que se esta filtrando.
- Ese widget es dueno de su campo de busqueda y lo arranca con lo que
  `filtroBibliotecaProvider` ya tenga. Con un controlador vacio (lo que hacia el
  panel) la lista sale recortada por un texto que no se ve en ninguna parte.
- Con un ejercicio ya elegido, el formulario **retira la lista** y deja lo
  elegido mas un boton de cambiar: al editar, lo que importa son las series.

**Hecho (elegir a que bloque va el ejercicio, CU-08):**

- El "+" del panel metia el ejercicio siempre en el **primer** bloque. Con una
  sesion de calentamiento mas fuerza eso nunca es lo que se quiere, y no se nota
  hasta que miras donde ha caido.
- Ahora, con mas de un bloque, se pregunta (`elegirBloque`), ensenando de cada
  uno su tipo y cuantos ejercicios lleva. Con uno solo no se pregunta: seria un
  clic de mas sin ninguna decision detras.

**Corregido (la descripcion seguia marcada como obligatoria en el formulario):**

- La etiqueta ponia "Descripción *" y el asterisco significa obligatorio en el
  resto de la app. Es opcional desde ayer; ahora lo dice el texto de ayuda.

**Documentacion:**

- `requirements.md` ya cuadra con el modelo: RF-02 dice que solo nombre y tipo
  son obligatorios, RF-02.1 anade el tercer tipo, RF-02.2 la taxonomia de dos
  niveles, RF-08 la eleccion de bloque y RF-08.1 el buscador y el filtro. CU-02
  y CU-08 llevan la secuencia nueva.
- `domain-model.md`: anotado por que la descripcion es opcional pero se guarda
  como cadena vacia (la columna es `not null`), para que el `text?` de la tabla
  no se lea como que admite `null`.

**Pendiente / notas:**

- `flutter test` **406** (tres del dialogo de bloque y dos del filtro del
  formulario), `dart analyze --fatal-infos` limpio. El SQL no se ha tocado en
  esta tanda.
- **Sigue sin comprobarse en el navegador.** Esta vez la app si arranca y pinta
  (218 frames en 1,5 s), pero los clics no llegan al lienzo: ni por coordenadas
  —el marco del panel va a 800x450 mientras el viewport es 1280x720— ni
  pulsando los nodos de accesibilidad desde JavaScript. Escribir si funciona,
  porque el texto va al `<input>` oculto del DOM. El servidor sigue levantado en
  el 54331.
**Corregido (la barra de navegacion y el atras habian desaparecido):**

- Sintoma: lo de ayer (barra de navegacion en toda pantalla con sesion, y la
  flecha de atras volviendo de donde se vino) ya no estaba.
- Causa, y **no era un fallo de codigo** ni un reset, como se penso al
  principio: lo cuenta el reflog. El 8 de octubre a las **23:18:16** se creo
  `ejercicios-v2` desde la punta de `dev`, que entonces era `6cdaad8`; el
  trabajo del navbar todavia **no era un commit**, eran cambios en el arbol. A
  las **23:18:49** se volvio a `dev` y a las **23:20:05** se commiteo alli
  (`752fa14`). Al volver a `ejercicios-v2` a las **23:44:01**, esos archivos ya
  estaban seguidos por git en `dev` y no existian en esta rama, asi que el
  cambio de rama los borro del disco: `pantalla_con_navegacion.dart`,
  `boton_atras.dart`, `sesion_falsa.dart` y el `conVuelta` de `rutas.dart`.
- **La leccion**: el trabajo sin commitear no pertenece a ninguna rama, flota en
  el arbol y te sigue al cambiar. Por eso al ramificar parecia que estaba todo.
  Una rama nueva hereda los *commits* de donde sale, nunca lo que haya a medias:
  antes de ramificar, `git status`, y si sale algo, decidir primero donde va.
- Arreglo: restaurado en el arbol. Los 13 archivos que esta tanda no tocaba,
  copiados tal cual de `752fa14` (`git checkout 752fa14 -- …`, que ahi no pisa
  nada porque coincidian con HEAD); los 7 que si, portados a mano hunk a hunk.
  El unico cambio real al portar es que el CTA del registro usa
  `_vaPorMinutos`, que es como se llama ahora ese getter.
- **Lo que falta es el historial**: el arbol esta bien, pero la rama sigue sin
  `752fa14`. Al mezclar `dev` habra conflicto en los archivos que tocan los dos
  lados, con el mismo contenido a ambos.
- Efecto colateral en los tests: el formulario de CU-08 lleva ahora barra
  inferior, y con el viewport de 600 px el boton de anadir serie cae debajo. Se
  agranda el viewport, como ya hacia el test del formulario de ejercicio.

**Corregido (la busqueda de la biblioteca y la del selector compartian estado):**

- Sintoma: buscar "sent" en el formulario de anadir ejercicio a un bloque y
  luego entrar en la biblioteca, que aparecia enseñando solo la sentadilla. Sin
  nada escrito en su buscador, y no volvia hasta escribir algo y borrarlo.
- Causa: los dos escribian en el mismo `filtroBibliotecaProvider`, y cada
  pantalla crea su propio controlador de texto vacio. El filtro seguia puesto y
  el campo no lo enseñaba.
- Arreglo: el filtro es ahora una familia por `AmbitoDeFiltro`. La biblioteca
  usa el suyo y el selector el suyo; el panel del planning y el formulario de
  CU-08 comparten el de seleccion a proposito, que son el mismo gesto en dos
  sitios. Ademas los dos campos de busqueda nacen con lo que su filtro ya tenga,
  que era la otra mitad del fallo.

**Corregido (los musculos iban pegados al nombre del grupo):**

- Mas aire entre la cabecera del grupo y sus chips en la lista plegable, y entre
  la fila de grupos y la de musculos en la biblioteca.

**Pendiente / notas (tercera tanda):**

- `flutter test` **410**, `dart analyze --fatal-infos` limpio. Tres tests nuevos
  comprueban que los dos ambitos de filtro no se pisan.
- Los 13 archivos restaurados quedan **en el indice** (`git checkout … --` los
  deja ahi). Si molesta: `git restore --staged .`, que no toca el contenido.
- Todo sin commitear: los commits los hace el.

### 2026-10-11

**Hecho (borrar el planning desde el editor):**

- `confirmarEliminarPlanning` ya existia, pero solo en la ficha del cliente.
  Ahora esta tambien en la cabecera del editor, que es donde se cometen los
  errores que hay que deshacer: crear la semana sin querer, o duplicar del
  origen equivocado. Borrar arrastra en cascada sesiones, bloques, ejercicios y
  series, asi que no hay que deshacer nada a mano.
- Con eso, duplicar se queda como estaba: **solo duplica**, no borra.

**Hecho (regla de dominio: lo pasado no se toca):**

- El entrenador no crea, modifica, borra ni duplica el planning de una semana
  terminada. Se trabaja la semana en curso y las siguientes.
- Dos excepciones: el **cliente sigue registrando** lo que hizo en una semana
  pasada que siga activa (entrena el domingo, lo apunta el lunes), y el
  entrenador **si puede archivarla**, que no cambia el plan y es justo cuando se
  archiva. Ademas archivar es lo que libera la semana en el indice unico.
- Consecuencia asumida y hablada: un error en una semana pasada ya no se
  deshace.
- En la base, migracion `20261011100000`: `semana_pasada()` calculada en
  `Europe/Madrid` (en UTC, entre las 00:00 y las 02:00 del lunes, la regla
  dejaria editar lo que ya es pasado) y un trigger en las cinco tablas de
  planificacion. **Triggers y no politicas RLS** por la trampa 8: un `update`
  bloqueado por RLS no da error, deja 0 filas y la app lo traduce a "eso ya no
  existe".
- En la app, el interruptor es `PlanningSemanal.esEditable`, que ya existia para
  los archivados. En el editor habia **14 puntos de escritura y solo 2 lo
  miraban**: alli el planning siempre estaba activo y la comprobacion era codigo
  muerto. Ahora lo miran todos, incluidas las celdas de la cuadricula (si no,
  dejarian teclear algo que el boton de guardar, apagado, no podria guardar) y
  el `+` del panel de biblioteca.

**Corregido (dos trampas de plpgsql que costaron la primera pasada):**

- El `and` de SQL **no garantiza cortocircuito**: el trigger compartido hacia
  `if tg_table_name = 'sesiones_entrenamiento' and new.planning_id ...` y, para
  las otras tablas, Postgres evaluaba igualmente el acceso al campo y reventaba
  con `42703`, *record "new" has no field planning_id*. Hay que anidar los `if`.
- `coalesce(new, old)` sobre registros pierde el tipo y los accesos a campos
  fallan con `22P02`. Cada rama usa `new` u `old` segun `TG_OP`.
- Lo desagradable fue el sintoma: 26 comprobaciones del script fallaron de
  golpe en sitios que no tenian nada que ver con la regla nueva, porque el
  trigger se dispara en cada escritura de planificacion.

**Corregido (dos detalles del formulario de ejercicio):**

- Los musculos secundarios enseñaban los seis grupos de golpe y alargaban el
  formulario aunque no se fuera a poner ninguno, que es el caso mas comun.
  Ahora van dentro de **otro** desplegable, cerrado de partida; al editar un
  ejercicio que ya tiene secundarios se abre solo, para que no parezca que no
  tiene ninguno.
- El `ChoiceChip` del tipo pintaba su marca de verificacion **encima** del
  icono y lo tapaba. Fuera con `showCheckmark: false`: que esta elegido ya se
  ve por el color.

**Corregido (el panel de biblioteca desbordaba al abrir dos grupos):**

- Sintoma: el rayado amarillo y negro de *BOTTOM OVERFLOWED BY 14 PIXELS* en el
  panel lateral del planning, al abrir dos grupos del filtro.
- Causa: el filtro y la lista estaban en un `Column` con el filtro **sin
  flexibilidad**. El filtro crece al abrir grupos, se queda con el alto que
  pida y deja al `Expanded` de debajo sin sitio. No hay nada que recortar: la
  columna desborda.
- Arreglo: un **unico scroll** para el filtro y los resultados. El filtro se
  desplaza con la lista y ya no hay alto que repartir.
- El aviso del `ListTile` que salia en consola era **otra cosa**: el panel vive
  dentro de un contenedor con color de fondo y los `ExpansionTile` pintan su
  tinta sobre el `Material` mas cercano, que quedaba por encima de ese fondo.
  Se arregla con un `Material` transparente propio del panel. No tenia nada que
  ver con el desbordamiento, aunque aparecieran juntos.
- Test de regresion (`panel_biblioteca_test.dart`), **comprobado contra la
  version anterior**: con el panel viejo falla con *overflowed by 123 pixels*.
  Dos cosas que costaron ahi: con la fuente de los tests (mas ancha que la
  real) el boton "Crear la semana" desborda a lo ancho, asi que el test monta
  la semana **con** planning; y los grupos llevan `PageStorageKey`, que
  `find.byKey(Key(...))` no encuentra.

**Corregido (el registro del cliente mezclaba ejercicios y reventaba tras un cardio):**

- Sintoma 1: al pulsar "Guardar y siguiente", el nombre del ejercicio cambiaba
  pero las series eran las del anterior, con el plan del nuevo al lado. Press
  militar tiene una serie planificada y salian dos, las de la sentadilla.
- Sintoma 2: al guardar un cardio, pantalla roja con *Unexpected null value*.
- Causa, la misma para los dos: al encadenar ejercicios con `context.go`, el
  widget ocupa el mismo sitio del arbol y Flutter **reutiliza su `State`**. Lo
  que se prepara en `initState` —los controladores de cada serie y el de
  minutos— se quedaba con lo del ejercicio anterior. Y viniendo de un cardio,
  que no crea ninguna serie, el mapa estaba vacio: la pantalla pedia
  `_campos[1]!` para la primera serie del siguiente y el `!` sobre `null`
  reventaba encima del entrenamiento.
- Arreglo en dos sitios: el enrutador pasa `key: ValueKey(ejercicio.id)`, asi
  que cada ejercicio estrena `State`; y la pantalla rehace sus campos en
  `didUpdateWidget` cuando cambia el id, para ser correcta tambien si alguien
  la monta sin clave. Ademas el `_campos[numero]!` pasa a crear la serie que
  falte: un desajuste es recuperable y no merece tirar la pantalla a media
  sesion.
- Dos tests nuevos, **comprobados contra la version anterior**: con ella fallan
  los dos (uno por las series heredadas, el otro por el *Unexpected null
  value*). Montan la pantalla **sin clave** a proposito, para probar que la
  pantalla aguanta por si misma y no solo porque el enrutador la proteja.

**Corregido (al terminar un dia, el cliente acababa en el siguiente):**

- El inicio del cliente abre por `siguientePendiente`, "la primera sesion sin
  terminar". Justo despues de acabar el Dia 1, esa es el Dia 2: al cliente le
  desaparecia de la vista lo que acababa de hacer. Pasaba **siempre** que
  quedara algun dia por hacer; si era el ultimo, no habia pendiente y se
  quedaba donde estaba, que es lo que confundia.
- Ahora al terminar se vuelve con `?dia=N` (`Rutas.inicioClienteEnDia`) y el
  inicio abre por ese dia. Lo que el cliente elija luego en la tira manda sobre
  el parametro.
- El parametro lo lee el **enrutador** y lo pasa como argumento, en vez de que
  la pantalla haga `GoRouterState.of`. Lo intente asi primero y rompio dos
  tests que la montan sin `GoRouter` encima: `of` revienta ahi, y en esta
  version de go_router no hay `maybeOf`. Inyectarlo ademas deja la pantalla
  montable suelta.

**Hecho (al crear un dia, el entrenador va a ese dia):**

- Lo pidio pensando que se habia roto al arreglar lo del cliente. **No era
  eso**: la eleccion de sesion del editor no se ha tocado en toda la sesion y
  el unico commit que la toco nunca es `ee84405`. Lo que parecia que iba es el
  caso de la **primera** sesion de una semana vacia: ahi no hay ninguna
  elegida y la pantalla cae en la primera, que es la nueva.
- Aun asi tiene sentido, y ahora `pedirDatosSesion` devuelve la sesion guardada
  en vez de un `bool`, de modo que quien la crea puede abrirla. Editar una
  existente no cambia de dia.

**Corregido (un fallo que me colé al hacer lo anterior):**

- Al reescribir `pedirDatosSesion` como expresion, el `reiniciar()` del
  controlador acabo **dentro del `builder`** del dialogo, que se ejecuta
  durante el build: *Tried to modify a provider while the widget tree was
  building*. Lo caza el test nuevo al abrir el dialogo; sin el, habria llegado
  a la app.

**Pendiente / notas:**

- `supabase db reset` aplica **24 migraciones**, `./scripts/probar_local.sh`
  **200/200** (ocho comprobaciones nuevas de la regla, incluida que archivar una
  semana pasada si se puede y que la semana en curso se sigue creando),
  `flutter test` **434**, `dart analyze --fatal-infos` limpio.
- `planningDePrueba` ya no fija la fecha: calcula la semana en curso. Con la
  fecha fija, los tests de edicion habrian empezado a fallar solos al cambiar de
  semana. Un test de `pantalla_planning` fijaba ademas una semana de septiembre
  para algo en lo que la fecha era incidental; se le ha quitado.
- Sin comprobar en el navegador, que lo mira el.


**Hecho (duplicar un planning semanal, CU-05 variante):**

- Se duplica **hacia la semana en la que estas**: te pones en la que quieres
  montar y eliges de que planning traerla. De las dos opciones que habia sobre
  la mesa (duplicar la semana anterior o una señalada), la segunda contiene a la
  primera y no cuesta mas.
- Boton con el icono de copiar a la izquierda de la flecha `<` del navegador de
  semanas. El navegador lo comparten entrenador y cliente, asi que la accion es
  opcional: al cliente le llega en `null` y el boton ni se pinta.
- Con la semana ya ocupada el boton se **deshabilita con el motivo** en vez de
  desaparecer: si desaparece, parece que la funcion no existe.
- El origen se elige de la lista de plannings del cliente, archivados incluidos.
  Un calendario dejaria señalar semanas vacias y el fallo solo se veria despues.

**Migracion `20261011090000_duplicar_planning.sql`:**

- Funcion `duplicar_planning(origen, fecha)`, `security invoker`. Va en Postgres
  por lo de siempre: son cuatro niveles anidados y decenas de `insert` que
  tienen que ir todos o ninguno, y PostgREST abre una transaccion por peticion.
- Copia **solo lo planificado**. Nada de lo realizado: ni series realizadas, ni
  minutos realizados, ni estado de registro, ni fecha realizada, ni el
  `resultado_registrado` de la sesion. Si se copiara, las graficas de CU-21
  contarian entrenamientos que no pasaron.
- Omite los ejercicios dados de baja y **devuelve cuantos** en un `jsonb`, para
  que la app lo diga. Al omitir uno renumera el bloque: copiar el orden original
  dejaria huecos (1 y 3) y la app calcula la siguiente posicion como "cuantos
  hay + 1", que chocaria con el indice unico del bloque.
- Verificada contra Supabase local con ocho invariantes antes de tocar Dart, y
  despues por la API en `probar_local.sh` con el token del entrenador, que es el
  camino de la app.

**Pendiente / notas:**

- `supabase db reset` aplica **23 migraciones**, `./scripts/probar_local.sh`
  **192/192** (ocho comprobaciones nuevas), `flutter test` **422**,
  `dart analyze --fatal-infos` limpio.
- Dos expectativas del script estaban mal puestas por mi y las corrigio la
  ejecucion: en ese punto el planning tiene dos ejercicios y no tres, y el
  cliente que intenta duplicar recibe **403**, no 500. El 403 es mas honesto de
  lo que yo esperaba: el planning es suyo y si lo ve, asi que no sale por "ya no
  existe"; lo para la politica de `insert`, que exige entrenador.
- Sin comprobar en el navegador, que lo mira el.


**Corregido (Clientes -> una ficha -> Plannings dejaba la app colgada):**

- Sintoma suyo: la aplicacion se bloquea. Lo que pasa de verdad es que la
  pantalla no llega a pintarse.
- Causa: en escritorio, `PantallaEntrenador` mete la cabecera dentro de un
  `Column` (la barra lateral llega hasta arriba, asi que no puede ir como
  `appBar` del `Scaffold`), y ahi recibe alto **sin acotar**. La cabecera de
  Plannings lleva `bottom` con el nombre del cliente, y eso revienta el layout:
  *RenderFlex children have non-zero flex but incoming height constraints are
  unbounded*.
- Arreglo: la cabecera va envuelta en un `SizedBox` con su
  `preferredSize.height`, que ya incluye el `bottom`.
- Se reprodujo **sin navegador**, montando la pantalla en un test
  (`plannings_cliente_test.dart`), que queda como regresion. No tenia ninguno.

**Corregido (los filtros de la biblioteca se pisaban entre pantallas):**

- Eran dos ambitos y ahora son tres: biblioteca, panel del planning y
  formulario de bloque. El panel y el formulario tampoco comparten, aunque
  sirvan para lo mismo: se ven en el mismo recorrido, y heredar el filtro del
  otro se lee como que la pantalla esta rota.
- Y el chip "Todo pierna" no se activaba si venias de pulsar un musculo:
  `cambiarGrupo` conserva el musculo cuando es de ese grupo, asi que el filtro
  seguia en "cuadriceps" y el chip no se marcaba. Ahora hay `verTodoElGrupo`,
  que lo suelta.

**Hecho (el cliente puede deshacer la serie de mas):**

- Las planificadas no se tocan: las pone el entrenador. La de mas si, mientras
  **no este confirmada**, que es el caso de pulsar el boton sin querer.
- Una vez confirmada ya no, y no es una limitacion de la pantalla:
  `series_realizadas` no tiene `delete` a proposito. Ofrecer la X ahi seria
  prometer algo que la base de datos no deja hacer. Queda como pendiente, con
  migracion, si lo quiere.
- Solo se puede quitar la **ultima**: quitar una de en medio dejaria un hueco en
  la numeracion, y las series se recorren del 1 al total.

**Hecho ("Guardar y siguiente ejercicio" guarda de verdad):**

- Antes solo navegaba, y lo escrito se perdia si no se habia pulsado el check
  verde de cada serie. Ahora manda todas las series con repeticiones puestas en
  una sola llamada (la RPC es idempotente, `on conflict do update`).
- Las filas vacias no entran: una serie sin repeticiones es una serie que no se
  ha hecho, y dejar un ejercicio a medias es valido. Sin nada que guardar, pasa
  de largo en vez de dar un error que seria mentira.

**Corregido (espaciados):**

- Aire entre la fila de grupos y la de musculos en la biblioteca, que es donde
  el lo veia pegado.
- Aire entre las tres tarjetas de la ficha del cliente (Plannings, Progreso y
  Control semanal), que iban con el margen por defecto de `Card`.

**Pendiente / notas:**

- `flutter test` **417**, `dart analyze --fatal-infos` limpio. El SQL no se ha
  tocado en esta tanda.
- A partir de ahora **las comprobaciones en el navegador las hace el**; aqui se
  verifica con tests y, cuando toque SQL, contra Supabase local. Los fallos de
  interfaz se reproducen montando la pantalla en un test de widget, que es como
  se cazo el bloqueo de Plannings.
- `dev` (commit `752fa14`) ya esta en el historial de la rama: rebase de
  `ejercicios-v2` sobre `dev`. Las partes que se habian portado a mano se
  colapsaron solas (git ve el mismo cambio en los dos lados); los cinco
  conflictos fueron la puntuacion de un texto de ayuda, el `case ... when` de la
  descripcion, `_esCardio` contra `_vaPorMinutos`, el viewport de un test y la
  bitacora, que se queda con **los dos lados**: su entrada del 8 y las del 9 y
  el 11.
- Todo sin commitear: los commits los hace el.

### 2026-10-12

**Corregido:**

- **Un cliente invitado podía quedarse sin forma de fijar su contraseña.** Pinchaba
  el enlace del correo, se salía de la pantalla antes de elegirla (o instalaba la
  PWA) y, al volver a pulsar el botón del correo, la app se quedaba cargando sin
  fin. Tres causas encadenadas, las tres arregladas:
  1. Los enlaces de Auth son de **un solo uso**: GoTrue borra el token al
     canjearlo y al segundo intento redirige con
     `#error=access_denied&error_code=otp_expired`. Eso **no llega como evento**,
     lo reporta el SDK como error del stream de `onAuthStateChange`, y
     `ControladorSesion` escuchaba sin `onError`: el estado se quedaba en
     `SesionDesconocida` y el enrutador aparcaba en la pantalla de carga. Ahora
     hay `onError`, y además se lee el error de la URL de arranque
     (`errorDeEnlaceDeCorreo`, con su test), así que el motivo se sabe sin
     depender de ningún evento.
  2. `/restablecer-contrasena` no era ruta pública, así que sin sesión el
     enrutador mandaba al login, donde un invitado no tiene ninguna contraseña
     que escribir. Ahora es pública y, sin sesión, esa pantalla explica que el
     enlace ya no vale y **ofrece pedir otro** ahi mismo (campo de correo +
     botón), reutilizando CU-24. Repetible cuantas veces quiera: el enlace sigue
     siendo de un solo uso —es la credencial de la cuenta y viaja en su buzón—,
     lo que no tiene límite es pedir uno nuevo.
  3. Un invitado rescatado por un enlace de **recuperación** veía "Nueva
     contraseña" y un "Volver al acceso" que no le servía de nada. El estado lo
     decide ahora el metadato `debe_fijar_contrasena`, no el evento
     `passwordRecovery`.
- Tope de espera (10 s) en la consulta del perfil: mientras no volvía, el estado
  seguía en `SesionDesconocida` y la pantalla de carga no se iba. Sale por
  `TimeoutException`, que ya se traducía a `ErrorConexion`.
- Los errores de Auth del stream se **traducen en el repositorio** (como los de
  cualquier otro método): ninguna `AuthException` sale de `data/`, ni por el
  valor ni por el error.
- El correo de invitación avisa de que el enlace se usa una sola vez y de elegir
  la contraseña antes de cerrar la página o instalar la app. **Toca
  `crear-cliente`: hay que redesplegar las funciones.**
- Un test de dominio con fecha fija (`2026-10-05`) se puso rojo solo al llegar el
  lunes 12: `esEditable` mira si la semana ya pasó. Pasa a calcular la semana en
  curso, que es lo que ya hacía la ayuda de tests. Es la trampa 28, otra vez.

**Hecho:**

- **Resend como SMTP de Auth** (en el panel, no en `config.toml`, para que local
  siga entregando en Mailpit). Sin eso, el correo de recuperación lo manda el
  servicio integrado de Supabase, que es de pruebas: remitente de Supabase y dos
  correos por hora. Verificado en producción con una cuenta real, y verificado de
  paso **lo que faltaba por saber**: un usuario invitado que nunca confirmó su
  cuenta **sí** recibe el correo de recuperación. Por eso el cliente puede
  rescatarse solo y no hace falta una Edge Function de "reenviar invitación".
- Documentado en `architecture.md` que el correo va por **dos caminos**: API de
  Resend para invitaciones y recordatorios, SMTP de Auth para la recuperación.
  El doc decía "Resend: invitaciones, recuperación, recordatorios" sin matizar, y
  eso era verdad a medias.
- Trampas 32, 33 y 34 en `estado-actual.md`; decisiones nuevas (ruta pública,
  campo de correo libre, la invitación manda sobre el tipo de enlace); CU-17 y
  CU-24 actualizados en `requirements.md`.

**Pendiente / notas:**

- `flutter test` **452**, `dart analyze --fatal-infos` limpio, `deno fmt --check`
  y `deno check` limpios. SQL sin tocar.
- **Subir el límite de envíos** en Authentication → Rate Limits: sigue en 2/hora,
  que era el del servicio integrado, y con dos intentos del cliente se agota. De
  10 a 20 es razonable; el captcha de Auth (`[auth.captcha]`, comentado en
  `config.toml`) es el escalón siguiente si alguna vez hay abuso.
- **Comprobado**: un cliente **dado de baja** no puede volver a entrar por un
  enlace de recuperación; la operación da error. El baneo de Auth también cierra
  esa puerta, no solo el login.
- **Pero el baneo no es inmediato**: el cliente que ya tiene la sesión abierta
  sigue entrando a todo hasta que caduque su token, incluso recargando. Es el
  siguiente asunto a tratar; sin empezar.
- Descartado el botón "Me han dado de alta y no tengo contraseña" en el login: no
  añade nada, porque esos casos ya se resuelven con el correo inicial y, si
  caduca, pidiendo otro enlace con su correo.
- En iOS, una PWA añadida a la pantalla de inicio tiene **su propio
  almacenamiento**, separado del de Safari: al instalarla, la sesión del enlace
  no viaja y la app abre sin sesión. En Android lo comparten. No se puede evitar;
  lo cubre el camino de pedir otro enlace.
- "Reenviar invitación" desde la ficha del cliente queda como comodidad, no como
  necesidad. Implica Edge Function nueva: sin empezar.

**Hecho (segunda tanda del día):**

- **El cliente entra por la semana en curso.** `_planningQueTocaVer` caía en
  `activos.firstOrNull` cuando no había planning de hoy, y la lista llega
  ordenada por `fecha_inicio` descendente: con la semana siguiente ya montada, el
  cliente abría la app y apareciía planificando el futuro. Ahora, sin planning de
  hoy, se enseña la semana en curso vacía, con su navegador. Tres tests.
- **Chips de Cardio y Fortalecimiento** en la biblioteca y en el filtro
  compartido (panel del planning y formulario de CU-08). **Se combinan** con el
  filtro muscular. Facetas nuevas (`tiposConEjercicios`) para no ofrecer un chip
  sin ejercicios detrás, e icono opcional en `ChipFiltro`, porque comparten fila
  con los grupos musculares y filtran otra cosa. Cuatro tests.
- **La tira de días del entrenador queda fija** al bajar la página. Comprobado
  que el test falla sin el arreglo: compara la posición del chip antes y después
  de arrastrar.
- **3x8 por defecto** al añadir un ejercicio de series, y la serie nueva hereda
  lo escrito en la anterior. Al editar no cambia nada.
- **La fila de serie es ahora un widget** (`presentation/widgets/fila_de_serie.dart`),
  con `CamposDeSerie` (los tres controladores y su `dispose`) separado de
  `FilaDeSerie` (lo que se pinta). Estaba escrita a mano dentro del formulario.
  **No se ha tocado la cuadrícula del editor del entrenador**: es otra fila
  —sin etiquetas, sin botón de quitar y con la columna de "la última vez" al
  lado— y unificarlas saldría un widget con seis banderas.

**Pendiente / notas (segunda tanda):**

- `flutter test` **462**, `dart analyze --fatal-infos` limpio.
- Del plan de siete puntos quedan: **duplicar un día** (migración nueva) y
  **mover días** (el grande: `orden` es identidad, no presentación). Sin empezar,
  a la espera de su visto bueno.
- `jwt_expiry` a 600 en producción, decidido por él: acota a diez minutos el
  acceso de un cliente recién dado de baja que ya tuviera la sesión abierta. El
  arreglo de fondo —que RLS mire `clientes.estado`— queda planteado y **sin
  hacer**: toca políticas, y no se toca sin aprobarlo.
- Descartado el botón "Me han dado de alta y no tengo contraseña" del login.

**Corregido (tercera tanda):**

- **En una semana pasada se podía pulsar "copiar a lo planificado".** Los campos
  se rellenaban con lo que hizo el cliente y después no había forma de guardar
  —el botón de guardar sí estaba deshabilitado—, así que parecía que el cambio
  se había perdido. Ahora sale deshabilitado, como editar y eliminar, con el
  motivo en el tooltip. La referencia **se sigue viendo**: consultar lo de la
  semana pasada es el motivo de abrirla.
- **Y el mismo fallo en "Añadir ejercicio"** de cada bloque, encontrado al
  repasar el archivo: en una semana pasada abría el formulario de un ejercicio
  que los triggers iban a rechazar. También deshabilitado.
- Repasados los demás botones de esa pantalla uno por uno: el resto ya consultaba
  `esEditable` (el panel de biblioteca incluido, por `puedeEditar`).
- Tres tests nuevos en `editor_semana_pasada_test.dart`, y comprobado que los dos
  que importan fallan sin el arreglo. El tercero vigila que las celdas de series
  sigan deshabilitadas, que ya lo estaban.

**Pendiente / notas (tercera tanda):**

- `flutter test` **465**, `dart analyze --fatal-infos` limpio.

**Hecho (cuarta tanda):**

- **X en el buscador de ejercicios** para borrar lo escrito de un toque, en los
  dos sitios que usan `CampoBusqueda` (la biblioteca y el filtro del panel y del
  formulario de CU-08). Solo aparece con algo escrito. Lo importante no es la X
  sino que **avisa al filtro**: vive en un provider, así que limpiar solo el
  controlador dejaría el campo vacío y la lista recortada por un texto que ya no
  se ve. Dos tests.
- **"Añadir serie" en la pantalla de planificación**, debajo de la cuadrícula de
  cada ejercicio. Antes obligaba a abrir el formulario del ejercicio, siendo lo
  que más se toca al montar la semana. La fila nueva **hereda** peso, reps y RIR
  de la anterior, igual que en el formulario, y **no guarda**: queda como cambio
  pendiente ("Sin guardar") y lo guarda el botón de siempre, que ya hace una
  llamada atómica por ejercicio. Deshabilitado en una semana pasada, como el
  resto. Tres tests, uno de ellos verificando que las dos series llegan al
  repositorio al guardar.
- Quitar una serie **sigue estando solo en el formulario**: no se ha tocado.

**Pendiente / notas (cuarta tanda):**

- `flutter test` **470**, `dart analyze --fatal-infos` limpio.

**Hecho (quinta tanda):**

- **La vista del planning de un cliente pasa a ser de resultados y de solo
  consulta** (`/entrenador/clientes/:id/plannings/:planningId`). El entrenador no
  tenía dónde ver lo que hacen sus clientes el mismo día: lo único que lo
  enseñaba era la columna de referencia del editor, y para llegar a ella había
  que ponerse a planificar la semana siguiente. Ahora:
  - **un día a la vez**, con tira de chips, en vez de la semana entera de corrido;
  - por ejercicio, **lo planificado al lado de lo que hizo** (serie a serie,
    emparejando por número y enseñando las que sobran de cualquiera de los dos
    lados, porque plan y realizado son independientes por regla de dominio), o
    los minutos en Cardio, con su estado (Registrado / Pendiente);
  - **sin acciones de escritura sobre el contenido**: añadir, editar, borrar y
    reordenar sesiones, bloques y ejercicios desaparecen de aquí. Se quedan las
    del planning entero, que no editan el plan y no tienen otro sitio: archivar o
    reactivar, cambiar el objetivo y eliminarlo. Si también quieres esas fuera, es
    quitar tres botones.
- **Botón "Visualizar resultados de la sesión"** a la derecha del nombre del día
  en el editor, que abre esa vista **por el día que se está planificando**
  (`?dia=N`, igual que ya hacía el cliente al terminar un ejercicio).
- **Quitar una serie desde la cuadrícula del editor**, con confirmación. Avisa
  si el cliente ya registró esa serie: lo que hizo **no se borra** (vive en
  `series_realizadas`, otra tabla), pero se queda sin plan enfrente con el que
  compararlo. La última serie no se puede quitar: un ejercicio que va por series
  necesita al menos una, y es mejor deshabilitar que fallar al guardar.
- **`TarjetaSesion` borrado** (368 líneas). Era lo que pintaba la semana en esa
  vista con sus diez callbacks de escritura; sin edición ya no tenía uso, y el
  editor tiene su propia pintura. En su sitio, dos widgets nuevos:
  `ResultadosDeSesion` y `ChipsDeDias`, este último compartido con el editor,
  que tenía su propia copia de la tira.
- `arrastre_planning_test.dart` colgaba de `TarjetaSesion`: reescrito contra
  `ListaArrastrable`, que es el widget que presta el arrastre de verdad (CU-11 y
  CU-12 siguen funcionando en el editor). Así no se cae cada vez que cambia la
  pantalla que lo usa.

**Pendiente / notas (quinta tanda):**

- `flutter test` **476**, `dart analyze --fatal-infos` limpio.
- **Sospecha de rendimiento sin confirmar**, a propósito del aviso
  `'requestAnimationFrame' handler took 245ms`: cada tecla en una celda de series
  llama a `onCambiarSeries`, que hace `setState` en
  `_PantallaPlanificacionEntrenadorState`, o sea **repinta la pantalla entera**
  del editor (incluido el panel de biblioteca) en cada pulsación. Encaja con el
  síntoma. El arreglo sería sacar el mapa de pendientes del `State` a un provider
  o un `ValueNotifier` y que solo se suscriban el botón de guardar y la fila. Sin
  medir y sin tocar.

**Hecho (sexta tanda):**

- **Añadir un ejercicio desde el panel de la biblioteca crea 3x8**, como el
  formulario de CU-08. Creaba **una** serie de 10 repeticiones, así que el atajo
  salía más caro que el camino largo. Usa las mismas constantes de dominio.
- **El check verde del cliente se apaga al corregir esa serie.** Confirmar
  guarda, pero después el cliente cambiaba un peso y el check seguía verde:
  la pantalla decía que lo que se ve es lo guardado cuando ya no lo era.
  - Lo guardado **no se pierde**: sigue en la base de datos hasta que se vuelva a
    confirmar, y "Guardar y siguiente" recoge lo escrito aunque no tenga check.
  - Hizo falta separar dos cosas que antes eran la misma: el check
    (`_confirmadas`, que ahora se vacía al editar) y **si la serie existe en la
    base de datos** (`_guardadas`, nuevo). Lo segundo es lo que decide si una
    serie de más se puede quitar, porque `series_realizadas` no tiene `delete`
    (trampa 15): sin separarlo, apagar el check habría dejado quitar de la
    pantalla una serie que sigue registrada.

**Pendiente / notas (sexta tanda):**

- El botón grande del día dice **"Comenzar entrenamiento"** mientras la sesión no
  tenga ningún ejercicio registrado; "Continuar" solo cuando de verdad hay algo
  empezado, y "Revisar la sesión" cuando no queda nada pendiente. "Continuar" en
  un día sin tocar era mentira, y de las que desaniman.
- **Tutorial de instalación de la PWA** en las dos pantallas de configuración,
  la del cliente y la de ajustes del entrenador: pasos para iPhone (obligatorio
  Safari) y para Android, plegado por defecto. Es una PWA, no hay ficha en
  ninguna tienda que lo explique, y en iPhone el **push no existe** hasta que la
  app está instalada; por eso en la pantalla del cliente va justo debajo de los
  avisos, donde se entiende por qué importa.
- `flutter test` **486**, `dart analyze --fatal-infos` limpio.
- Todo sin commitear: los commits los hace él.

### 2026-10-14

**Hecho:**

- **El buscador de ejercicios busca solo por nombre, y perdona la ortografía.**
  Ignora mayúsculas, tildes, diéresis y la virgulilla de la eñe, normalizando los
  **dos** lados (lo escrito y el nombre guardado), así que "frances" encuentra
  "Press francés" y "bánca" encuentra "Press banca". Y deja de mirar el
  equipamiento y los nombres de la taxonomía: escribir "pecho" sacaba ejercicios
  de espalda porque el pectoral era secundario suyo, y nadie entendía el
  resultado. Para los músculos están los chips, que además dicen por qué está
  filtrado.
- **`seriesPorDefecto` vuelve a 1**, a petición de Aimar; estuvo en 3 entre el 12
  y el 14. Los tests que afirmaban "tres" se reescribieron **en función de la
  constante**, no del número, así que el siguiente cambio de criterio no los
  rompe.

**Pendiente / notas:**

- `flutter test` **488**, `dart analyze --fatal-infos` limpio.
- **Peso "por lado": consultado, a la espera de aprobación.** Implica migración y
  tocar `guardar_ejercicio_planificado`, así que no se empieza sin su visto
  bueno. La propuesta está en el pendiente de `estado-actual.md`.

- **Peso "por lado"**, aprobado e implementado (pedído el 09).
  - Migración `20261014090000_peso_por_lado.sql`, **verificada contra Supabase
    local**: `ejercicios.peso_por_lado boolean not null default false` y la
    columna añadida al final de `vista_progreso_ejercicios` (que ya hacía join
    con `ejercicios`). Comprobado que marcar propaga a las 14 filas de la vista
    del seed y que desmarcar las devuelve a cero.
  - Va en **el ejercicio**, no en el ejercicio planificado: así no hay que
    copiarlo en los tres sitios que crean ejercicios planificados y el dato
    llega solo a las pantallas, porque la consulta ya incrusta `ejercicios(*)`.
  - Interruptor en el formulario de la biblioteca, **solo para lo que va por
    series** (en un cardio no hay kg que etiquetar). Marcar no pregunta;
    **quitar la marca sí**, porque alcanza al histórico.
  - Se ve: badge azul "Kg por lado" en la cuadrícula del entrenador, en la ficha
    del ejercicio, en la vista de resultados y sobre la gráfica de progreso; y
    como texto "7,5 kg por lado" en el resumen del planning del cliente y en su
    pantalla de registro.
- `flutter test` **495**, `dart analyze --fatal-infos` y `dart format
  --set-exit-if-changed` limpios. 25 migraciones aplicadas sin incidencias.

**Hecho (vista del cliente):**

- **El día del cliente va separado por bloques**, con su nombre y la nota del
  entrenador encima de sus ejercicios. Antes era una lista plana donde no se
  veía dónde acababa uno. Solo presentación: el modelo no cambia, el orden ya lo
  ponía el entrenador. De paso, la **nota del bloque** deja de estar escondida
  dentro de cada ejercicio.
- **El botón de continuar anuncia el bloque que empieza**: "Guardar y comenzar el
  bloque Fuerza" cuando el ejercicio actual cierra el suyo. Dentro del mismo
  bloque sigue diciendo "Guardar y siguiente ejercicio", y en el último del día,
  "Terminar ejercicio".
- `BotonCta` envuelve su texto en un `Flexible` con ellipsis: la etiqueta nueva
  es larga ("Guardar y comenzar el bloque Calentamiento") y en un móvil estrecho
  un `Text` suelto dentro de una `Row` desborda en vez de recortarse.
- `flutter test` **499**.

**Hecho (packs, fase 1):**

- **Modelo y SQL**, verificados contra Supabase local con un script de 25 casos:
  `packs`, `pack_ejercicios`, `pack_series` con RLS de solo entrenador, dos
  triggers de tipo estricto, y tres funciones:
  `guardar_ejercicio_del_pack` (ejercicio + series en una transaccion),
  `reordenar_pack_ejercicios` y `aplicar_pack_a_bloque`.
- **Dos bugs cazados por esa verificacion**, los dos invisibles leyendo el SQL:
  `v_faltan || 'texto'` reventaba por "malformed array literal" (falta un
  `::text`), y el renumerado en dos fases aparcaba en negativo contra un
  `check (orden > 0)`; ahora aparca hacia arriba. Las funciones equivalentes del
  planning solo funcionan porque esas tablas no llevan ese check.
- **Lado Dart**: entidades `Pack`/`PackEjercicio`/`PackSerie`, `DatosPack` y
  `DatosPackEjercicio` con su validacion, el puerto `PackRepositorio`, su
  implementacion Supabase y `ControladorPacks`. En `lib/features/packs/`.
- **Reutilizado**, no duplicado: `DatosSerie` entera (las series de un pack son
  las mismas y sus tres validaciones tambien) y, de camino, el mapa de la RPC
  sube a `DatosSerie.aJsonDeRpc()`, que estaba escrito a mano en el repositorio
  del planning.
- 25 tests nuevos: validaciones del dominio, el JSON con relaciones incrustadas
  (el fallo de `PlanningSemanal` que dejaba la lista vacia) y el controlador con
  repositorio falso.

**Pendiente / notas (packs):**

- `flutter test` **529**, `dart analyze --fatal-infos` y `dart format
  --set-exit-if-changed` limpios. **28 migraciones** aplicando limpias.
- Fases 2 y 3 sin empezar: la pantalla de Packs y el panel de planificacion con
  las dos pestanas.
- Pendiente tambien lo de **reordenar con flechas** en vez de arrastrando, que
  se decidio para los packs y **tambien para el planning**: sale un
  `ListaOrdenable` compartido que sustituye a `ListaArrastrable` en las dos
  pantallas.

**Hecho (packs, fase 2):**

- **Pantalla de Packs**, quinto destino del entrenador. Lista con el tipo, el
  numero de ejercicios y, en ambar, el aviso de los packs **vacios**: no se
  pueden aplicar a ningun bloque, y mas vale decirlo ahi que al intentarlo.
- **Ficha del pack**: sus ejercicios en orden con lo que tengan preparado, el
  formulario para anadir y editar, quitar con confirmacion, y borrar el pack
  entero (avisando de que lo ya planificado no se toca, porque se copio).
- **`ListaOrdenable`**: reordenar **con flechas** en vez de arrastrando, como se
  decidio. Mismo contrato que `ListaArrastrable` (`desde`/`hasta` ya corregidos),
  asi que las funciones de Postgres que renumeran no cambian. Queda pendiente
  llevarlo tambien al planning, que es la otra mitad de esa decision.
- **Formulario de ejercicio del pack**: reutiliza `FiltroDeEjercicios` (con un
  ambito propio, `formularioPack`) y `FilaDeSerie`/`CamposDeSerie` del planning.
  El filtro se abre **restringido al tipo del pack**, para que no se pueda elegir
  algo que el trigger va a rechazar al guardar. Y la tabla de series empieza
  **vacia**: no preparar nada es una opcion, no un formulario a medias.
- Crear el pack abre su ficha directamente: se crea para meterle ejercicios, no
  para mirarlo en la lista.
- El **tipo no se puede cambiar al editar**: sus ejercicios son de ese tipo, y
  cambiarlo dejaria dentro cosas que no encajan.

**Pendiente / notas (packs, fase 2):**

- `flutter test` **541**, `dart analyze --fatal-infos` y `dart format
  --set-exit-if-changed` limpios.
- Falta la **fase 3**: el panel de planificacion con las dos pestanas
  (Biblioteca | Packs) y el "+" que aplica el pack a un bloque.
- Y llevar las flechas al planning, sustituyendo `ListaArrastrable` en bloques y
  ejercicios.
- Todo sin commitear: los commits los hace él.

**Corregido (packs, fase 2):**

- **La pantalla de Packs se quedaba colgada** con un bucle de "BoxConstraints
  forces an infinite width". Misma causa que la pantalla negra del formulario de
  ejercicio: el tema da a los `FilledButton` `Size.fromHeight(52)`, que es ancho
  minimo **infinito**, y el boton "Nuevo pack" vive en una `Row`, que no acota el
  ancho. Arreglado con un `minimumSize: Size(0, 44)` local, el mismo que lleva
  "Guardar cambios" en el planning; el tema no se toca porque los CTA de ancho
  completo dependen de el.
- **Por que los tests no lo vieron**: `pantalla_packs_test.dart` montaba la app
  sin el tema real. Ahora pasa `TemaApp.oscuro()`, y con el tema y sin el arreglo
  fallan los 4 tests de la lista. Ojo con esto en los tests de pantallas nuevas:
  sin `tema:` este fallo no se reproduce.
- `flutter test` **541**, `dart analyze --fatal-infos` y `dart format` limpios.

**Hecho (packs, fase 3):**

- **Panel de la planificacion con dos pestanas, Biblioteca | Packs** (RF-25).
  Es un `SegmentedButton` dentro del mismo `_PanelBiblioteca`, asi que vale
  igual para el panel fijo de escritorio y para el modal de movil. El titulo
  pasa a "Añadir a la sesión", que sirve para las dos pestanas.
- **El `+` de un pack** elige bloque igual que un ejercicio suelto: sin bloques
  avisa, con uno va directo y con varios pregunta. La logica comun sale a
  `_bloqueDestino`, y `elegirBloque` recibe un `nombre` en vez de un
  `Ejercicio` para servir a los dos.
- Tras aplicar, la pantalla **recarga el planning ella misma**:
  `ControladorPacks` no sabe de plannings, y sin esa recarga el pack entraba en
  la base de datos pero no se veia. Comprobado que el test falla si se quita.
- El aviso dice cuantos ejercicios entraron y **cuantos se quedaron fuera por
  estar de baja** (la RPC los omite). Si no entro ninguno, no dice "añadido".
- Los **packs vacios** salen con el `+` apagado, porque la RPC los rechazaria.
  Mientras se aplica uno, los `+` tambien se apagan, para no aplicarlo dos veces.
- 10 tests nuevos en `panel_packs_test.dart`, montados con el tema real.

**Pendiente / notas (packs, fase 3):**

- `flutter test` **551**, `dart analyze --fatal-infos` y `dart format` limpios.
- Sin probar en el navegador; lo prueba él.
- Queda **llevar las flechas al planning** (`ListaOrdenable` en lugar de
  `ListaArrastrable` en bloques y ejercicios).
- Todo sin commitear.

**Hecho (flechas en el planning):**

- **Bloques y ejercicios del planning se reordenan con flechas**, la otra mitad
  de la decision del 19. `ListaOrdenable` pasa a `lib/core/presentacion/widgets/`
  (ya no es solo de packs) y de ella sale `FlechasDeOrden`, publico, que el
  planning coloca **en la cabecera** de cada bloque y de cada ejercicio, donde
  estaba el asa. Ponerlas fuera, como hace `ListaOrdenable`, con dos listas
  anidadas se comia dos margenes de ancho en movil.
- Las claves de las flechas llevan el id (`bajar_bloque_<id>`,
  `subir_ejercicio_<id>`): con varias listas en la misma pantalla, el indice no
  basta para distinguirlas.
- Mismo contrato `desde`/`hasta`, asi que `moverBloque`, `moverEjercicio` y las
  funciones de Postgres no cambian.
- **Borrados** `ListaArrastrable` y `arrastre_planning_test.dart`. Los sustituye
  `ordenar_planning_test.dart`, contra la pantalla: comprueba que cada flecha
  mueve **su** lista y la manda entera, los extremos apagados por lista, y que
  en una semana pasada no se mueve nada.
- Comentarios y docs (`requirements.md`, `ui-design.md`) que decian "arrastrando"
  actualizados.

**Corregido (flechas en el planning):**

- La cabecera del bloque desbordaba 13 px en movil con las flechas, que son mas
  anchas que el asa: el texto iba suelto con un `Spacer`. Ahora va en un
  `Expanded` con elipsis.

**Pendiente / notas (flechas en el planning):**

- `flutter test` **551** (salen 4 de arrastre, entran 4), `dart analyze
  --fatal-infos` y `dart format` limpios.
- Los dos borrados estan **sin pasar al indice** (` D` en `git status`): hay que
  incluirlos en el commit.
- A 390 px y con la fuente de los tests, la fila de acciones movil de la
  planificacion (selector de cliente y navegacion de semana) desborda 120 px.
  **Ya pasaba antes** de este cambio. Con la fuente real puede que no se note,
  pero conviene mirarlo en un movil estrecho.
- Sin probar en el navegador; lo prueba él.

**Hecho (ajustes de biblioteca y del registro del cliente):**

- **Filtros principales de la biblioteca**: Todos, Fuerza, Cardio,
  Fortalecimiento y, solo para el entrenador, Dados de baja, excluyentes entre
  si. Salen siempre los tres tipos, haya o no ejercicios de cada uno (antes los
  tipos vacios no se ofrecian y Fuerza no tenia chip).
- **Los musculos solo aparecen con Fuerza o Fortalecimiento**: grupos (mas
  "Sin clasificar" si hay) y, al elegir grupo, sus musculos.
- **Fuerza y Fortalecimiento comparten el filtro muscular**: pecho en Fuerza y
  luego Fortalecimiento ensena el fortalecimiento de pecho, con el chip marcado.
  Al pasar a Todos, Cardio o Dados de baja se **suelta**: ahi los musculos no se
  ven, y un filtro invisible recortando la lista parece un fallo.
- Va en `PestanaBiblioteca` (deducida de `tipo` y `soloEliminados`, no
  guardada aparte, para que no se contradigan) y en
  `FiltroBiblioteca.elegirPestana`. Solo afecta a la pantalla de biblioteca: el
  filtro del panel del planning y de los formularios no cambia.
- **Registro del ejercicio (cliente)**: el enlace "Ver vídeo de ejemplo" pasa a
  ser un boton **"Vídeo"**, con **"Descripción"** a su derecha, que abre en una
  hoja inferior la explicacion del ejercicio (`descripcion` del dominio). Cada
  boton solo sale si hay algo detras; la descripcion es opcional.
- Tests: 5 nuevos en la biblioteca (tipos fijos, musculos solo en Fuerza y
  Fortalecimiento, musculo compartido, se suelta en Cardio, bajas de cualquier
  tipo) y 4 en el registro; 5 existentes adaptados a pulsar Fuerza antes de
  ver los grupos.

**Pendiente / notas (ajustes):**

- `flutter test` **559**, `dart analyze --fatal-infos` y `dart format` limpios.
- Sin probar en el navegador; lo prueba él.
- Decision abierta: si prefiere que un tipo sin ejercicios no salga, es volver a
  filtrar los chips por `FacetasBiblioteca.tipos`.

**Hecho (chip de Fuerza en el panel del planning):**

- El filtro del panel de biblioteca del planning (y de los formularios que usan
  `FiltroDeEjercicios`) ofrece ya **Fuerza** junto a Cardio y Fortalecimiento.
  Antes se dejaba fuera por ser la mayoria, pero sin el no habia forma de quitar
  de la lista el cardio y el fortalecimiento. Los chips siguen saliendo de
  `FacetasBiblioteca` (solo tipos con ejercicios) y siguen cruzandose con el
  filtro muscular.
- Test nuevo en `panel_biblioteca_test.dart`. `flutter test` **560**, analyze y
  format limpios. Sin probar en el navegador.

**Corregido (iconos en blanco en produccion):**

- **Algunos iconos no salian** (los anadidos en los ultimos despliegues). Causa:
  Flutter recorta la fuente de iconos en cada build a los que usa la app, pero
  la publica siempre como `assets/fonts/MaterialIcons-Regular.otf`, y
  `vercel.json` servia `/assets/` un ano con `immutable`. El navegador se quedaba
  con la fuente de su primera visita. Confirmado en el build local: la fuente
  recortada pasa de 15 344 a 15 988 bytes con el mismo nombre.
- Arreglo sin que nadie tenga que borrar la cache:
  - `web/flutter_bootstrap.js` (plantilla nueva) carga los assets desde
    `/v/<version>/` con `assetBase`.
  - `scripts/vercel_build.sh` pone de version los 12 primeros caracteres de
    `VERCEL_GIT_COMMIT_SHA` (o la hora, si no lo hay) y falla si no consigue
    ponerla.
  - `vercel.json`: rewrite de `/v/:version/assets/*` a `/assets/*`; lo
    versionado sigue un ano e inmutable, y `/assets/` a secas pasa a
    revalidarse siempre.
  - En local (`flutter run` o un build sin el script) el marcador no se
    sustituye y se cargan los assets de siempre.
- Comprobado en local: `flutter build web` usa la plantilla, la sustitucion del
  script deja la version y el motor (`main.dart.js`) lee `assetBase`.

**Pendiente / notas (iconos):**

- **Sin probar en Vercel**: la rewrite solo existe alli. Tras el push a `dev`,
  mirar en la pestana Network que la fuente se pida en `/v/<commit>/assets/...`
  con 200 y que los iconos salgan.
- Los usuarios que ya tienen la fuente vieja la siguen teniendo guardada, pero
  ya no se pide: la app nueva pide otra URL. No hace falta que hagan nada.
- `canvaskit/` sigue con `immutable` y nombre fijo. Hoy no molesta (el motor
  carga CanvasKit del CDN de Google, con la version del motor en la URL), pero
  si alguna vez se compila con `--no-web-resources-cdn`, al subir de Flutter
  tendria el mismo problema.

**Hecho (documentacion del dominio):**

- `docs/domain-model.md` no tenia los packs. Anadidas las entidades 11 (Pack),
  12 (Ejercicio del pack) y 13 (Serie del pack), con sus reglas sacadas de la
  migracion `20261019090000_packs_de_entrenamiento.sql`: tipo estricto, solo el
  entrenador, aplicar es copiar, bajas omitidas, borrado fisico, todo lo
  preparado opcional y series y minutos excluyentes.
- Corregido lo que ya no era verdad: bloques y ejercicios se reordenan **con
  flechas**, y un Cardio planificado puede quedarse **sin minutos** (migracion
  `20261019090100_cardio_sin_minutos.sql`).
- Anadida la regla de los filtros principales de la biblioteca y el filtro
  muscular compartido entre Fuerza y Fortalecimiento.

**Pendiente / notas:**

- `docs/sql-schema.md` tampoco recoge las tablas ni las funciones de los packs.

**Hecho (sql-schema.md al dia con los packs):**

- Seccion nueva **"Packs de entrenamiento (RF-25)"**: las tres tablas con sus
  checks e indices, el patron de permisos y la politica unica de solo
  entrenador, los dos triggers del tipo estricto
  (`validar_ejercicio_del_pack`, `validar_serie_del_pack`) copiados de la
  migracion, y en prosa las tres RPC (`guardar_ejercicio_del_pack`,
  `reordenar_pack_ejercicios`, que aparca sumando por el `check (orden > 0)`, y
  `aplicar_pack_a_bloque`, con lo que devuelve y cuando falla).
- **Cardio sin minutos**: el bloque de `validar_tipo_ejercicio_planificado` pasa
  a la version de `20261019090100`, con una nota de por que se relajo.
- De paso: las tablas de packs anadidas a la lista de las que conceden
  `delete`, y "arrastra" cambiado por "mueve (con flechas)" en el reordenado.

**Pendiente / notas:**

- `sql-schema.md` **no recoge nada de la fase 6** (recordatorios, `pg_cron`,
  Vault, `20261018090000_recordatorios_fallan_a_la_vista.sql`). Es un hueco
  anterior; esas notas viven hoy en `estado-actual.md` (trampa 36).

**Hecho (copias de seguridad):**

- La app estaba en produccion **sin ninguna copia**: el plan gratuito de
  Supabase no las hace, y la mitigacion de `architecture.md` (un `pg_dump` como
  artefacto de CI) nunca llego a montarse.
- `.github/workflows/copias.yml`, cada noche a las 02:30 UTC y a mano con
  *Run workflow*:
  - Vuelca roles, esquema y datos con `supabase db dump`, por el session pooler
    (la conexion directa es solo IPv6). Comprueba que el volcado trae
    `auth.users` y las tablas principales, lo empaqueta y lo cifra con **age**
    antes de subirlo a R2 (`bd/diarias/`, y la del dia 1 tambien a
    `bd/mensuales/`).
  - Sincroniza los dos buckets de forma incremental con `rclone sync` a un
    remoto `crypt`. Lo borrado o reemplazado va a `storage-historico/<fecha>/`.
  - Si falta un secreto, **falla** en vez de saltarse.
- `scripts/restaurar_copia.sh`: descifra, `db reset --no-seed` y carga los datos
  en una transaccion, con el `psql` del contenedor de la base local.
- `docs/copias-de-seguridad.md`: que se copia, las claves que solo tiene él,
  la puesta en marcha (R2 en jurisdiccion UE, reglas de caducidad, Environment
  `copias` con 12 secretos) y los tres procedimientos de restauracion.

**Corregido (antes de llegar a produccion, gracias a probarlo):**

- **Tablas internas de Storage en el volcado**: la restauracion fallaba con
  "permission denied for table buckets_vectors". Son del rol interno de Storage
  y no guardan nada de la app; se excluyen con `-x`.
- **Choque con los buckets**: el reset los vuelve a crear desde `config.toml` y
  la copia tambien los trae. Se borran dentro de la misma transaccion antes de
  cargar.
- **rclone lo volvia a subir todo cada noche**: el S3 de Supabase da la hora de
  modificacion con milisegundos al listar y redondeada en otro sitio, y `crypt`
  no compara hashes. Habria llenado el historico con una copia de cada foto por
  noche. `--modify-window 1s` lo arregla; comprobado con dos noches seguidas
  sin cambios y un reemplazo.
- `docker cp` no encontraba el archivo en Git Bash con `MSYS_NO_PATHCONV=1`: la
  ruta del lado de Windows se pasa con `cygpath`.

**Comprobado contra Supabase local:** volcado real, cifrado con age en un
Ubuntu 24.04 (los mismos paquetes de apt que el runner), restauracion con el
script tal cual: mismos recuentos antes y despues, login 200 y 400, sin
temporales en disco. Storage: nombres cifrados, nada en claro, foto borrada
recuperada byte a byte, noches sin cambios sin subidas.

**Pendiente / notas (copias):**

- **Sin activar**: faltan el bucket de R2, las claves y el Environment `copias`.
  Despues, primera copia a mano y primer ensayo.
- Sin probar la conexion con **R2 de verdad** (solo con una carpeta local) ni la
  restauracion en un **proyecto nuevo** de Supabase.
- Ensayo de restauracion cada 3 meses o tras un cambio grande de esquema.
- Anadir Cloudflare como encargado del tratamiento en el registro del RGPD.

### 2026-10-21

**Hecho:**

- **Verificacion nocturna de las fotos copiadas** (`copias.yml`, paso nuevo
  "Verificar la copia de Storage"). Tras el `sync`, `rclone cryptcheck
  --one-way` compara la huella cifrada de cada original con la que R2 guarda
  de su copia, sin descargar nada. Un solo archivo distinto pone el job en
  rojo. Hasta ahora el verde solo decia que cada archivo estaba en R2 con su
  tamano.
- **Casilla "depurar"** en *Run workflow*: una pasada sin reintentos con las
  cabeceras HTTP de cada llamada, para ver que operacion devuelve un error.
- Probado contra Supabase local: `cryptcheck` da "0 differences found" con la
  copia intacta y "hashes differ" (con error) con un byte cambiado en la copia
  cifrada. La rama de diagnostico conserva el codigo de salida de rclone (0 si
  va bien, error si falla) y muestra el codigo HTTP de cada llamada.

**Corregido:**

- Antes de llegar a produccion: con `-vv`, rclone 1.60 escribe cada variable de
  configuracion **con su valor**, claves de Storage incluidas
  (`Setting secret_access_key="..." from environment variable`). En GitHub
  saldria tapado por el enmascarado de secretos, pero la contrasena de `crypt`
  va "ofuscada", que se revierte. El modo de diagnostico filtra esas lineas con
  `grep -v`; comprobado que despues no queda ninguna clave en el log.

**Pendiente / notas:**

- **El 501 de la primera copia real**: cada foto dio `501 NotImplemented` en el
  primer intento y se copio bien en el segundo, asi que el job salio en verde.
  Contra Storage local no pasa: viene de R2. Falta una pasada con **depurar**
  para ver que llamada lo devuelve, y corregirlo en vez de vivir del reintento.
- Ver en la proxima ejecucion que `cryptcheck` funciona contra R2 de verdad.
  Necesita que R2 de la huella md5 de cada archivo, y en local se probo con una
  carpeta, no con R2.
- Las entradas del 19 y el 20 quedaron bajo el encabezado del 14, sin fecha
  propia. No se han movido.

**Corregido (copias, mas tarde el mismo dia):**

- **Causa del 501 de R2**, vista con la casilla "depurar": el `PUT` de cada foto
  a R2 da 200 y devuelve un `X-Amz-Version-Id`. rclone 1.60 comprueba entonces
  lo subido con un `HEAD ?versionId=...`, que R2 no admite (501). La foto
  siempre estaba subida: el reintento la encontraba igual y la saltaba.
- Arreglo: `RCLONE_CONFIG_R2_NO_HEAD=true` en el remoto de R2. Comprobado en un
  Ubuntu 24.04 que la opcion existe en rclone 1.60 y que la lee de la variable.
  La comprobacion que se pierde la cubre, entera, `cryptcheck`.
- El log tambien confirma que R2 devuelve el `Etag` (md5) de cada archivo, que
  es lo que necesita `cryptcheck`.

**Pendiente / notas:**

- Tras el push, otra pasada con "depurar": tiene que salir el `PUT` con 200 y
  ningun 501. Despues, una normal, para ver `cryptcheck` en verde contra R2.
- **Comprobado contra R2 de verdad**: tras el arreglo, la verificacion sale en
  verde con "0 differences found". `cryptcheck` funciona con R2 y las fotos
  copiadas son identicas a las de Supabase.
- Sigue pendiente el **primer ensayo de restauracion con una copia real**:
  descargar una `bd-...tar.gz.age` de R2 y pasarla por
  `scripts/restaurar_copia.sh`. Hasta ahora solo se ha restaurado una copia
  sacada de la base local.
- **`restaurar_copia.sh` fallaba en Windows al descifrar** ("El sistema no puede
  encontrar la ruta especificada"). El script apaga la conversion de rutas de
  Git Bash (`MSYS_NO_PATHCONV=1`, por `docker cp`), y el `age` de winget es un
  ejecutable nativo de Windows: recibia `/c/Users/...` sin convertir. En el
  ensayo del 19 no salio porque se uso un `age` dentro de Docker que traducia
  las rutas el solo. Ahora las rutas que reciben programas nativos pasan por
  `ruta_nativa` (`cygpath -w` si existe). Comprobado con el `age` de winget: una
  copia cifrada y descifrada con esas rutas sale intacta.

**Hecho (ensayo completo de restauracion con una copia real):**

- **Base de datos**: copia real de R2 (`bd-2026-10-21`) descifrada y cargada en
  local con `restaurar_copia.sh`. Bien.
- **Fotos**: `scripts/restaurar_storage.sh` (nuevo) sube los archivos de R2 al
  Storage local y comprueba con `cryptcheck` que cada uno es identico a la
  copia, descargandolo. Resultado: "Todo correcto", 0 diferencias en los dos
  buckets (3 fotos de progreso y 140 imagenes de ejercicios), y las imagenes se
  ven en la app local.
- Con esto, la cadena entera esta probada de verdad: copia nocturna, R2,
  descifrado y restauracion de la base y de las fotos.

**Corregido (cazado por el ensayo):**

- **Tras restaurar la base, `rclone copy` no subia ninguna foto, sin dar
  error.** El Storage de Supabase responde al listado desde `storage.objects`,
  no desde los archivos; la base restaurada ya traia las 143 fichas con su
  tamano y su fecha, y rclone las dio por subidas. Las fotos salian en blanco.
  **El procedimiento de desastre de la guia tenia el mismo fallo.** Arreglado
  con `--no-check-dest` en el script y en la guia; reproducido y comprobado
  antes en local (ficha sin archivo: GET 500; con `--no-check-dest`: se sube y
  se descarga identica).
- La primera version del script tenia una "comprobacion del indice" que no
  servia: comparaba `storage.objects` con un listado que sale de esa misma
  tabla. Quitada; la comprobacion buena es `cryptcheck`, que descarga.
- La comprobacion guardaba la salida de rclone y se quedaba minutos callada
  mientras reintentaba. Ahora muestra la salida en el momento, con reintentos
  cortos y tiempos maximos.

**Pendiente / notas:**

- `supabase db reset` en local tras el ensayo, para quitar los datos y fotos
  reales de los clientes.
- Proximo ensayo: dentro de 3 meses o tras un cambio grande de esquema.
- Sin ensayar la restauracion en un **proyecto nuevo** de Supabase.
- winget instala rclone 1.75 en local y el workflow usa el 1.60 de apt. El
  ensayo funciono con el 1.75; si algun dia algo se comporta distinto en local
  y en CI, empezar por ahi.

**Corregido (errores vistos en produccion):**

- **No se podia anadir un ejercicio a un bloque tras quitar uno.** Aimar quito
  el 6.o de 7: quitar no renumera, quedaban las posiciones 1-5 y 7, y la app
  proponia "cuantos hay + 1" = 7, ocupada. Pasaba en cuatro sitios: el
  formulario de ejercicio, el "+" del panel, y el formulario de bloque (su
  posicion por defecto y el selector). Ahora todos usan `siguientePosicion`
  (`datos_planificacion.dart`): la mas alta + 1. Sin migracion. Tests: la
  funcion, y el caso de Aimar en el panel (propone la 8).
- **"Kg por lado" en movil** iba al lado del nombre y lo dejaba sin sitio.
  Ahora, por debajo de `anchoEscritorio`, va debajo del nombre; en escritorio
  sigue al lado. Tests de los dos casos.
- `flutter test` **567**, analyze y format limpios.

**Pendiente / notas:**

- **Quedan huecos en las posiciones**: el arreglo evita el choque, pero no
  renumera. En bloques se ve ("BLOQUE 1, BLOQUE 3", tambien en la vista del
  cliente). Y `aplicar_pack_a_bloque` calcula la posicion con `count(*)`, asi
  que aplicar un pack a un bloque con huecos tambien choca. Propuesta pendiente
  de OK: migracion que renumere al borrar, corrija los huecos que ya hay y haga
  que la RPC use `max(orden)`.
- **Push en produccion**: "Vapid subject is not a valid URL. prueba@gmail.com".
  El secreto `VAPID_SUBJECT` de las Edge Functions tiene que ser una URL
  (`mailto:...`). Arreglo de configuracion pendiente (lo hace Daniel). Mientras,
  el correo sigue de respaldo.

**Hecho (renumerado al borrar, con OK de Daniel):**

- Migracion `20261021090000_renumerar_al_borrar.sql`: al quitar un ejercicio de
  un bloque o un bloque de una sesion, los demas se renumeran solos (triggers
  por sentencia que llaman a `renumerar_ejercicios_del_bloque` y
  `renumerar_bloques_de_la_sesion`). Corrige una vez los huecos que ya hay en
  produccion, como el bloque de Aimar. `aplicar_pack_a_bloque` pasa a
  `max(orden)`. Las sesiones no se renumeran, a proposito.
- Diseno corregido antes de probar: con las funciones cerradas a la app
  (`revoke from public`), un trigger normal no habria podido llamarlas, porque
  corre con el rol de quien borra. Los triggers son `security definer`.
- Probada contra local como el entrenador real, en 9 casos (ver
  `sql-schema.md`), y 4 comprobaciones nuevas en `probar_local.sh` por la API:
  quitar el primero deja 1,2; cabe uno en "cuantos hay + 1"; el cliente recibe
  403 al llamar al renumerado.

**Corregido:**

- `probar_local.sh` tenia una comprobacion rota desde el 19: "Cardio con
  minutos" insertaba en la posicion 2, que ya ocupaba "Cardio SIN minutos" desde
  que esa se acepta (`20261019090100`): 409. Ahora usa la 3.

**Pendiente / notas:**

- `probar_local.sh` **204/204**, **29 migraciones** limpias, `flutter test`
  **567**.
- Migracion sin desplegar: la aplica el CI en el siguiente push a `dev`.
- Push: falta cambiar `VAPID_SUBJECT` a `mailto:...` en produccion. Sin
  decidir si se endurece la Edge Function para aceptar un correo sin `mailto:`.

**Corregido (login sin teclado en el movil):**

- Con la contrasena **visible**, fallar el login dejaba el movil sin teclado:
  tocar los campos ya no lo abria. Con la contrasena oculta no pasaba. Causa
  probable (no se puede reproducir el teclado del navegador en un test): al
  pulsar Acceder el campo seguia enfocado y la peticion lo desactivaba
  (`enabled: !enCurso`); desactivar un campo enfocado obliga al motor web a
  desmontar su `<input>` a la fuerza, y visible es de tipo `text` en vez de
  `password`.
- Arreglo en `pantalla_login.dart` y, por el mismo patron, en
  `pantalla_restablecer_contrasena.dart`: se quita el foco antes de enviar y,
  durante la peticion, los campos pasan a `readOnly` en vez de desactivarse.
- Test nuevo: contrasena visible, enviar desde el teclado, durante la peticion
  el campo esta sin foco, de solo lectura y no desactivado; tras el fallo,
  tocarlo lo vuelve a enfocar. Comprobado que falla con el codigo anterior.

**Pendiente / notas:**

- **Probarlo en el movil**, que es donde se veia: contrasena visible, fallar y
  tocar otra vez el campo.
- `VAPID_SUBJECT` ya cambiado por Daniel a `mailto:...`: la Edge Function no se
  toca.

### 2026-10-25

**Corregido:**

- **Un dia nuevo no ensenaba "la ultima vez" de ningun ejercicio.** Aimar
  planifico 4 dias a un cliente cuya semana anterior tenia 3, y en el Dia 4 no
  salia ninguna referencia; el mismo ejercicio en el Dia 3, si. Causa: sin Dia 4
  en la semana anterior, `referenciasDelDia` devolvia un `const {}`, y
  `referenciasDeSesion` le hacia `removeWhere`, que **lanza** sobre un mapa
  constante ("Cannot modify unmodifiable map"). El calculo moria antes de llegar
  al historico, y la pantalla, que trata el error de esa ayuda como "no hay
  nada" (`.value ?? {}`), dejaba el dia en blanco sin avisar.
- Arreglo: `referenciasDelDia` devuelve un mapa normal tambien sin sesion, y
  `referenciasDeSesion` filtra al copiar, sin modificar lo que recibe.
- Antes de encontrarlo se descartaron, con datos de produccion: que faltara
  `fecha_realizada` (el historico del cliente tiene 102 filas para esos
  ejercicios) y que la consulta fallara por tiempo (14 ms, todo con 200).
- Tests: el recorrido de Aimar (semana anterior de 3 dias, Dia 4 abierto vacio,
  anadir un ejercicio) y un control con el Dia 4 ya relleno; los dos fallaban
  antes del arreglo. Mas uno de dominio: el mapa vacio se puede modificar.
- `flutter test` **571**, analyze y format limpios.

**Pendiente / notas:**

- El error estuvo oculto porque la pantalla se traga los fallos de las
  referencias. Se valoro registrarlo y ensenar un aviso; Daniel decidio que no
  hace falta, con el arreglo basta.
- Sin desplegar ni commitear.

### 2026-10-27

**Hecho (packs con varios tipos, peticion de Aimar):**

- Un pack puede **mezclar tipos de ejercicio** (por ejemplo, cardio y fuerza), y
  sus **etiquetas de tipo** pasan a ser varias, al menos una. Decision de
  Daniel: las etiquetas son **solo descriptivas**, no limitan que ejercicios
  admite el pack, y se pueden cambiar al editar.
- Migracion `20261027090000_packs_varios_tipos.sql`: `packs.tipo` pasa a
  `packs.tipos tipo_ejercicio[]` con `check (cardinality(tipos) >= 1)`; los
  packs existentes quedan con `array[tipo]`. Un trigger normaliza las
  etiquetas (sin repetidos, en el orden del enum). `validar_ejercicio_del_pack`
  ya no compara con el pack, y la exclusion series/minutos pasa a decidirla el
  tipo **del ejercicio** (en los dos triggers, con `planifica_con_minutos`).
  `aplicar_pack_a_bloque` no cambia: ya iba ejercicio a ejercicio, y un bloque
  admite cualquier tipo.
- App: `Pack.tipos`, `DatosPack.tipos` con validacion "al menos uno",
  `DatosPackEjercicio.tipo` pasa a ser el del ejercicio elegido. Dialogo con
  chips de seleccion multiple. El formulario de ejercicio ya no restringe el
  filtro y elige series o minutos segun el ejercicio. Nuevo widget compartido
  `IconoDelPack` + `etiquetaDeTipos` ("Fuerza + Cardio"), que sustituye al
  cuadrado copiado en la lista, la ficha y el panel del planning.
- Probada contra local como el entrenador, 8 casos (ver `sql-schema.md`), y
  convertidos los packs que habia.
- Tests nuevos: dominio (sin tipos; orden del enum), lista y dialogo (pack
  mixto, crear con dos tipos, sin ninguno no guarda) y el formulario (un cardio
  en un pack de fuerza pide minutos y se guarda asi; cambiar a fuerza vuelve a
  las series). `flutter test` **579**, analyze y format limpios.

**Pendiente / notas:**

- **Desplegar la base y la app juntas**: la app anterior lee `packs.tipo`, que
  ya no existe.
- `build_runner` regenero `pack.freezed.dart` y `pack.g.dart`: van en el commit.
- No se ha hecho `supabase db reset` para no borrar los datos locales de
  Daniel; la migracion se aplico con `supabase migration up` sobre ellos.
