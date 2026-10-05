# Estado actual del proyecto

Resumen operativo para retomar el trabajo. Complementa a `AGENTS.md` (convenciones)
y a `bitacora.md` (histórico cronológico): aquí está **dónde estamos, qué trampas
ya se han pisado y qué queda abierto**.

Última actualización: 2026-10-05, con lo realizado la última vez visible al planificar y datos de demostración en el seed.

## Fases

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1 | Esqueleto, `perfiles`/`clientes`/`ejercicios`, autenticación (CU-01, CU-24) | Hecha y verificada |
| 2 | Biblioteca de ejercicios (CU-02 a CU-04) | Hecha y verificada |
| 3 | Gestión de clientes + Edge Functions reales (CU-17 a CU-19) | Hecha y verificada |
| 4 | Planificación semanal (CU-05 a CU-16) | Hecha y verificada |
| 5 | Progreso del cliente (CU-20, CU-21, medidas, check-in) | Hecha y verificada |
| 6 | Notificaciones (CU-22) | Hecha y verificada en local |
| — | Despliegue en la nube (Supabase + Vercel + CI/CD) | **Pendiente** |

Verificación actual: `supabase db reset` aplica **18 migraciones** limpias,
`./scripts/probar_local.sh` da **177/177**, `flutter test` **353**,
`dart analyze --fatal-infos` sin incidencias, `flutter build web` compila.

Para que el script llegue a las Edge Functions hace falta **también**
`supabase functions serve --no-verify-jwt` en otra terminal: sin él, esas
comprobaciones no se saltan, fallan con 503 y "name resolution failed".

## Cómo arrancar el entorno

Hacen falta **dos terminales** más la app:

```bash
supabase start                            # necesita Docker Desktop abierto
supabase db reset                         # migraciones + seed
```

```bash
supabase functions serve --no-verify-jwt  # imprescindible para alta/baja de clientes
# solo si el contenedor del edge runtime se niega a arrancar (trampa 23):
#   ./scripts/servir_funciones_host.sh
#   BASE_FUNCIONES=http://127.0.0.1:54331 ./scripts/probar_local.sh
```

```bash
./scripts/run_dev.sh                      # o F5 en VS Code
```

Cuentas de prueba y contraseña: al principio de `supabase/seed.sql`. Correo de
pruebas: Mailpit en <http://127.0.0.1:54324>.

**Datos para trastear** (`supabase/seed_demo.sql`, cargado también por
`supabase db reset`): 15 ejercicios de biblioteca y un cliente de demostración,
**Ana Demo** (`demo@local.test`, misma contraseña), con tres semanas de
planificación: dos archivadas y con resultados registrados, y la de esta semana
activa y sin registrar. Trae a propósito los casos que cuesta montar a mano:
una sesión a medias, un ejercicio que está esta semana y la anterior no (para
ver la referencia "Última vez · dd/mm"), cardio con minutos realizados, medidas
y check-in. Para arrancar con la base pelada, quita ese archivo de
`[db.seed] sql_paths` en `config.toml`.

El cliente de demostración es **otro distinto** de `cliente@local.test` a
propósito: `probar_local.sh` usa ese y le crea un planning activo de la semana en
curso, así que si el seed le dejara uno, el índice de "un planning activo por
cliente y semana" tumbaría ese bloque entero con un 409.

`./scripts/probar_local.sh` verifica 177 cosas por la API REST. **Requiere partir de
`supabase db reset`**: el propio script da de baja al cliente del seed al comprobar
el bloqueo de acceso, así que una segunda pasada avisa y sale.

## Trampas ya pisadas (no volver a tropezar)

Cada una costó una depuración; están todas verificadas contra Supabase local.

1. **`service_role` SÍ necesita `GRANT`.** Salta RLS (`BYPASSRLS`) pero no los
   privilegios de tabla. Sin él, una Edge Function recibe
   `permission denied for table`. El `sql-schema.md` decía lo contrario y se
   corrigió. Ya concedido en `perfiles`, `clientes` y las seis tablas de
   planificación (solo `select` en estas últimas, para CU-22).
2. **`dart analyze --fatal-infos`, nunca `flutter analyze`.** `riverpod_lint` 3.x
   usa el sistema de plugins nuevo y solo `dart analyze` lo carga; con
   `flutter analyze` el proyecto sale limpio pero las reglas de Riverpod no se
   evalúan. Varias de ellas son `info`, de ahí `--fatal-infos`.
3. **Riverpod autoDispose + diálogos.** Un provider `@riverpod` leído solo con
   `ref.read(...notifier)` dentro de un `onPressed` se desecha antes de que el
   usuario conteste al diálogo, y al volver lanza `UnmountedRefException` (la app
   parecía congelarse). Regla: la pantalla que lance la operación **observa** el
   controlador con `ref.watch`, los métodos **devuelven su `Result`** en lugar de
   dejarlo solo en `state`, y el notifier comprueba `ref.mounted` tras cada `await`.
4. **PostgREST abre una transacción por petición.** Varias operaciones que deben ser
   atómicas van en una función de Postgres invocada por RPC, no en varias llamadas.
   Ver `guardar_ejercicio_planificado`: `security invoker`, para que RLS y los
   triggers sigan aplicando dentro.
5. **`AFTER UPDATE OF columna`** se dispara según las columnas **mencionadas en la
   sentencia**, no las que cambian. Un trigger `before` que modifique esa columna no
   lo activa. Usar `AFTER UPDATE` con `when (old.x is distinct from new.x)`.
6. **Puerto 54330, no 3000.** Windows (Hyper-V/Docker) reserva bloques del rango
   dinámico TCP, que aquí va de 1024 a 15000; el 3000 cayó dentro y dejó de poder
   bindearse con `errno 10013`. El puerto debe coincidir **a la vez** en
   `scripts/run_dev.sh`, `.vscode/launch.json`, `site_url` y
   `additional_redirect_urls` de `config.toml`, y `APP_BASE_URL` del `.env`.
7. **Las migraciones aplicadas se tratan como inmutables.** En la fase 3 se añadieron
   los `grant` editando migraciones ya aplicadas; en local no se notó porque
   `db reset` recrea todo, pero en la nube no se reaplican. Cualquier corrección va
   en un archivo nuevo.
8. **RLS en un `UPDATE` no devuelve 403**: el `USING` impide ver la fila, la petición
   afecta 0 filas y PostgREST responde 2xx. Para comprobarlo hay que contar las filas
   devueltas con `Prefer: return=representation`, no esperar un código de error.
9. **Riverpod 3**: `AsyncValue.valueOrNull` no existe, es `.value`. `ProviderObserver`
   es `base`, así que la subclase debe ser `final`.
10. **`psql -q`** en scripts: sin él, un `insert ... returning id` pega la línea
    `INSERT 0 1` al uuid y lo corrompe en silencio.
11. **Un cliente invitado se crea sin contraseña**, y GoTrue emite `signedIn` (no
    `passwordRecovery`) al abrir el enlace de invitación. Sin distinguirlo, el cliente
    entraba sin fijar contraseña y luego no podía volver a entrar. Se resuelve con el
    metadato `debe_fijar_contrasena`, que pone `crear-cliente` y limpia
    `establecerNuevaContrasena`.
12. **`user_banned` llega con statusCode 400**, el mismo que las credenciales
    inválidas. El `switch` tiene que mirar el `code` antes del status, o un cliente
    dado de baja vería "correo o contraseña incorrectos".

13. **`objects_path` en un bucket de `config.toml`** precarga en el bucket los
    ficheros de esa carpeta local. Si la carpeta no existe, el arranque falla al
    sembrar (`NotFound: FileSystem.stat`). Como git no versiona carpetas vacías, una
    copia recién clonada se lo come. No se usa: no hay objetos de ejemplo.
14. **Una vista sobre tablas con RLS necesita `with (security_invoker = on)`.** Sin
    esa opción corre con los permisos de su dueño y puentea las políticas de las
    tablas de debajo. Las dos vistas de progreso la llevan.
15. **`series_realizadas` no tiene `delete`**, así que registrar no puede ser
    "borrar y volver a insertar" como en la planificación: la RPC de CU-20 usa
    `on conflict do update`. Y como el `on conflict` evalúa además la política de
    `insert`, que exige planning activo, corregir lo registrado de una semana ya
    archivada no es posible.
16. **PostgREST no traduce `no_data_found` (P0002) a 404**: devuelve 500. La app no
    mira el código HTTP sino el `code` del cuerpo, así que el mensaje al usuario es
    el correcto, pero en los logs aparece un 500 que no es un fallo real.

17. **PostgREST devuelve los recursos incrustados con el nombre de la TABLA**, no
    con el del campo de la entidad: `sesiones_entrenamiento`, no `sesiones`. Si al
    campo le falta su `@JsonKey`, `@Default([])` deja la lista vacía **sin dar
    ningún error**, y la pantalla se ve coherente pero vacía. Pasó con
    `PlanningSemanal.sesiones` (toda la semana salía como descanso). Al añadir una
    relación incrustada, comprobar la clave en el `.g.dart` generado.
18. **Ni el script de la API ni los tests de widget ven ese fallo**: el primero no
    pasa por las entidades y los segundos las construyen a mano. Hace falta un test
    que parsee la respuesta real (`planning_json_test.dart`).
19. **En un test de widget el viewport son 600 px** y un `ListView` solo construye
    lo visible: una semana entera no cabe. Sin agrandar
    `tester.view.physicalSize`, el test afirma que faltan sesiones que sí están.

20. **`dart analyze` no mira la rama web de un import condicional.** Un
    `dart:js_interop` mal usado (por ejemplo, un tear-off de un miembro externo,
    que Dart prohíbe) pasa el análisis y revienta en `flutter build web`. Con
    código de plataforma, el build web es parte de la verificación, no un extra.
21. **`deno lint` prohíbe el especificador `npm:` en línea**: las dependencias de
    las Edge Functions van por el import map de `supabase/functions/deno.json`.
22. **pg_cron programa en UTC**, no en la zona del servidor. La hora de la
    expresión y el cálculo de "hoy"/"mañana" son dos cosas distintas: lo segundo
    lo hace la función en `Europe/Madrid`.

23. **Docker 29 y el contenedor del edge runtime.** Durante un rato,
    `supabase functions serve` y `supabase start` fallaron con `failed to copy
    edge runtime main service into container: destination
    "supabase_edge_runtime_...:/" must be a directory`, y Studio con
    `mkdir /run/desktop/mnt/host/c: file exists`. Reiniciar Docker Desktop
    arregló lo de Studio; lo del edge runtime acabó arrancando solo tras
    descargarse la imagen de nuevo, y desde entonces el script pasa entero por
    Kong. Actualizar la CLI de Supabase (2.118.0 → 2.119.0) no cambió nada.
    Si vuelve a pasar: `supabase start -x studio -x edge-runtime` levanta el
    resto, y `./scripts/servir_funciones_host.sh` sirve las tres funciones con
    el Deno del host (puerto 54331) para `BASE_FUNCIONES`. Lo único que ese
    apaño no cubre es el salto desde Postgres por Kong, porque esa URL apunta al
    contenedor que falta.

24. **Una dependencia sin versión fija rompe el CI sola, sin tocar código.**
    `supabase/functions/deno.json` pedía `npm:@supabase/supabase-js@2`, así que
    cada ejecución resolvía la última 2.x. El día que `auth-js` movió `data`
    dentro de `options` en `GenerateInviteOrMagiclinkParams`, `deno check` empezó
    a fallar con `TS2353` en `crear-cliente` sin que nadie hubiera cambiado nada.
    Ahora está fijada (2.117.2), como ya lo estaba `web-push`. Curiosidad útil: el
    código **funcionaba** igual con `data` en la raíz, porque la librería monta el
    cuerpo con `{...resto, ...options}`; era un fallo de tipos, no de
    comportamiento, y por eso el script local nunca lo vio.
25. **`deno check` solo miraba dos de las tres funciones.** `enviar-recordatorios`
    se añadió en la fase 6 y no se incluyó en el paso del CI, así que su código no
    pasaba por el comprobador de tipos. Ya están las tres.

## Decisiones tomadas (no reabrir sin motivo)

- **CU-24 mantiene el mensaje genérico** cuando el correo no está registrado: no se
  confirma si una cuenta existe. Decisión confirmada explícitamente.
- **`riverpod_lint` se activa por el bloque `plugins:`** de `analysis_options.yaml`,
  sin `custom_lint` (que ya no interviene en la versión 3.x).
- **`SUPABASE_PUBLISHABLE_KEY`** es el nombre en la app y en `config/*.json`. Dentro
  de las Edge Functions los nombres los fija Supabase: `SUPABASE_PUBLISHABLE_KEYS`
  (plural, JSON) y `SUPABASE_ANON_KEY` como respaldo; **no existe** el singular.
- **Bajas lógicas** en clientes y ejercicios; **borrado físico** en planificación
  (plannings, sesiones, bloques, ejercicios planificados, series planificadas),
  porque ahí eliminar es un caso de uso real y la cascada se encarga.
- **El vídeo de ejemplo se reproduce dentro de la app** (2026-10-04), incrustando
  el reproductor de YouTube en un iframe montado como vista de plataforma. Sustituye
  a la solución provisional de la fase 2, que solo copiaba el enlace al portapapeles.
  El enlace copiable **sigue debajo**: hay vídeos cuyo dueño no permite incrustar, y
  los enlaces que no son de YouTube no se pueden reproducir aquí.
- La vista del planning es **la misma pantalla para entrenador y cliente**, con
  `puedeEditar: false` para el segundo. Un planning archivado tampoco es editable.
- **El registro de CU-20 es serie a serie** y guarda en cada confirmación la lista
  completa de series confirmadas, no solo la última: así la llamada es idempotente y
  corregir una serie anterior la actualiza en su sitio. Dejar un ejercicio a medias
  es válido.
- **La gráfica de CU-21 se pinta con `CustomPainter`**, sin librería de gráficas.
  La única dependencia nueva de la fase 5 es `image_picker`.
- **Las fotos se convierten siempre a PNG** antes de subirlas (reducidas a 1600 px),
  nunca se sube el fichero original. Ver `architecture.md`, "Conversión de la imagen
  antes de subirla".
- **Dos buckets, con criterio distinto**: `fotos-progreso` privado (dato personal,
  URL firmada) e `imagenes-ejercicios` público (material de la biblioteca, se pinta
  en listas). Lo que decide no es la comodidad, es si el contenido es de alguien.
- **La imagen del ejercicio se sube al guardar el formulario**, no al elegirla, y
  se compensa borrándola si el guardado falla.
- **Push web con VAPID, sin Firebase ni ninguna dependencia nueva en Flutter**: el
  puente con el navegador es JavaScript en `web/index.html` llamado con
  `dart:js_interop`. Decisión consultada y confirmada.
- **El correo no se puede desactivar.** La pantalla de preferencias solo ofrece el
  interruptor del push.
- **Un push no enviado se registra como `omitido`**, con su motivo, en
  `avisos_enviados`. No es un hueco: es lo que pide la excepción de CU-22.
- **Las sesiones se numeran, no se fechan** (2026-10-04): un planning tiene Día 1,
  Día 2… con índice único `(planning_id, orden)`, y el entrenador decide cuántas
  sesiones hay, no en qué día caen. El motivo es real: si el cliente no puede ir el
  miércoles y va el jueves, es la misma sesión. Lo que sí se guarda es
  `fecha_realizada`, el día en que la hizo, y lo rellena un trigger en el primer
  registro: hoy no condiciona nada, solo es el eje de la gráfica de CU-21. **Esto
  invierte la regla de la fase 4** ("la planificación se hace sobre un calendario"),
  por decisión explícita; `AGENTS.md`, `domain-model.md` y `sql-schema.md` ya la
  llevan cambiada. Arrastró a CU-22: ver el punto siguiente.
- **CU-22 avisa de la semana, no de "mañana"** (2026-10-04): sin fecha planificada no
  se puede decir "mañana tienes sesión", así que el recordatorio de entrenamiento pasó
  a enviarse el día en que arranca el planning, resumiendo cuántas sesiones trae la
  semana. El aviso del día de control no cambia: ese sí depende de un día real.
- **El orden de bloques y ejercicios se cambia arrastrando** (2026-10-04), con
  dos funciones de Postgres (`reordenar_bloques`,
  `reordenar_ejercicios_planificados`) que renumeran el conjunto entero en una
  transacción. No se puede con `update` sueltos: el índice único del orden
  rechaza los estados intermedios, y PostgREST abre una transacción por
  petición. Reciben la lista completa de ids, no "mueve este de 3 a 1".
- **Reordenar es solo del entrenador, y hay que comprobarlo a mano** en la
  función: el cliente tiene política de `update` sobre
  `ejercicios_planificados` para registrar sus minutos de cardio, y una política
  RLS no puede limitar **qué columnas** se tocan. Se vio en el script, que
  devolvía 204 donde esperaba 403. Es la "nota de seguridad conocida" de
  `sql-schema.md`, que sigue abierta para el `update` directo a la tabla.
- **Al planificar se ve lo que el cliente hizo la última vez** (2026-10-05), en
  una columna a la derecha de las series, con un botón que lo copia a lo
  planificado. Es como trabaja el entrenador: parte de la semana pasada y ajusta.
  La referencia es el Día N del planning anterior y, si esa semana no hizo ese
  ejercicio, el último registro que haya, **diciéndolo con la fecha** ("Última vez
  · 16/09") para que nadie planifique creyendo que es de hace siete días.
  Sin SQL nuevo: sale de la jerarquía que ya se carga y de
  `vista_progreso_ejercicios`. Detalle en `architecture.md`.
- **La foto del ejercicio se pinta en un único widget** (`MiniaturaEjercicio`),
  compartido por la biblioteca, la planificación y el registro del cliente.
  Antes cada pantalla tenía su copia del hueco gris, y por eso la planificación
  se quedó sin imagen cuando se añadió a la entidad.
- **Medidas y check-in no comparten guardado**: dos formularios, dos botones, dos
  operaciones. Es lo que dice el modelo de dominio, no una limitación.

## Pendientes abiertos

Decisiones que quedaron sin cerrar:

- **Bucket de Storage** de las fotos de progreso: `fotos-progreso` ya está
  declarado en `config.toml` y **creado y verificado en local** (privado, 20 MiB,
  png/jpeg), con sus **políticas ya escritas** (migración
  `20261003090200_politicas_storage_fotos_progreso.sql`) y verificadas. Falta solo
  crearlo en la nube cuando haya proyecto. El detalle está en `architecture.md`,
  sección "Almacenamiento de ficheros".
- **Resend sin dominio verificado**: `RESEND_API_KEY` y `RESEND_FROM_EMAIL` siguen sin
  valor real. En local las invitaciones se entregan en Mailpit vía `CORREO_DEV_URL`.
  Cuando haya dominio, basta rellenar las variables: no hay que tocar código.
- **Reactivar un cliente dado de baja**: hoy no se puede volver a darlo de alta con el
  mismo correo (Auth no admite duplicados, aunque el índice de `clientes` sí lo
  permita entre bajas). Devuelve 409 con un mensaje que lo explica. No es un caso de
  uso del ERS; queda por decidir si se añade.
- **Anotar en `AGENTS.md`** la regla de migraciones inmutables (trampa 7).
- **`linguist-generated=true`** en `.gitattributes` oculta los `.g.dart` en los diffs
  de GitHub y los excluye de las estadísticas de lenguaje. Si para el TFG interesa que
  cuenten, hay que quitar esas dos líneas.
- **`docs/sql-schema.md`** usa `auth.role() = 'authenticated'` en la política de
  lectura de `ejercicios`; las migraciones usan `to authenticated`. Ambos funcionan en
  una petición normal, pero `auth.role()` devuelve `NULL` si la sesión no trae los
  claims. Queda por unificar doc y código.

## Lo que queda: desplegar

Las seis fases del ERS están implementadas y verificadas **en local**. Lo que falta
no es funcionalidad, es puesta en producción.

El **pipeline ya está escrito**: el job `desplegar` de `.github/workflows/ci.yml`
aplica las migraciones (`supabase db push`) y publica las Edge Functions
(`supabase functions deploy`) en cada push a `dev` y a `main`, después de que
pasen análisis, tests y las comprobaciones de Deno. El proyecto al que va lo
decide el **Environment** de GitHub, que se llama como la rama (`main`, `dev`),
porque los secretos son suyos. Mientras un entorno no tenga secretos, el job se
salta solo y lo dice en el resumen, en vez de poner la rama en rojo.

**El despliegue lo lleva Actions, no la integración del panel de Supabase.** Ese
proyecto tenía la integración de GitHub conectada a `main` (branching con
`git_branch: main`), que aplicaba las migraciones por su cuenta **sin mirar el
CI**: con los tests en rojo desplegaba igual. Se desconecta en el panel del
proyecto; si se dejan las dos, cada push despliega dos veces.

Secretos por Environment (Settings → Environments):

| Secreto | De dónde sale |
| --- | --- |
| `SUPABASE_ACCESS_TOKEN` | Account → Access Tokens, en el panel de Supabase |
| `SUPABASE_PROJECT_REF` | El ref del proyecto (está en la URL del panel) |
| `SUPABASE_DB_PASSWORD` | La contraseña de Postgres de ese proyecto |

Lo que **no** hace el pipeline, a propósito: la web (la despliega Vercel con su
integración de GitHub), los secretos de las funciones y los de Vault (son
valores, no código: se ponen una vez a mano y no tienen por qué pasar por un log
de CI) y el seed (es solo local).

Queda por hacer:

1. **Desconectar la integración de GitHub** en el panel del proyecto, para que
   el despliegue no se haga por duplicado.
2. **Crear los tres secretos del entorno `main`**, apuntando al proyecto que ya
   existe (`app-aimar-trainer-dev`, ref `aihlqyyeqrybhrawxkut`, eu-west-1).
   Después, crear los buckets
   `fotos-progreso` e `imagenes-ejercicios` desde el panel: sus políticas sí
   viajan en migración, pero los buckets en sí los crea `config.toml`, que es
   cosa de local.
3. **Los dos secretos de Vault** del job de recordatorios, con la URL real de la
   función y un `secreto_cron` largo y aleatorio. La migración del job crea
   `pg_cron` y `pg_net` y la función que los lee, pero no los secretos: sin
   ellos el job se dispara y no llega a ninguna parte. (Se podrían automatizar
   con la sección `[db.vault]` de `config.toml`, que `db push` aplica antes de
   las migraciones; está sin decidir.)
4. **Secretos de las Edge Functions**: `supabase secrets set` con
   `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `APP_BASE_URL`, `SECRETO_CRON` (el
   mismo que el de Vault) y un par VAPID **propio de producción** (el de local no
   vale).
5. **Resend con dominio verificado**. Hasta entonces, las invitaciones y los
   recordatorios solo llegan a Mailpit en local.
6. **Vercel**: la configuración ya está en `vercel.json` (instala el SDK de
   Flutter 3.47.5, compila con los `--dart-define` leídos de las variables de
   entorno del proyecto y publica `build/web`). Falta importar el repo en Vercel,
   crear allí las cuatro variables (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
   `APP_ENV`, `VAPID_PUBLIC_KEY`) y, una vez haya dominio, **apuntarlo en los
   sitios que dependen de él**: `APP_BASE_URL` de las Edge Functions y las *Redirect
   URLs* de Auth en el panel de Supabase, o los enlaces de invitación y de
   recuperación no llevarán a ninguna parte.
7. **Proyecto aparte para pruebas** (opcional): crearlo, rellenar el Environment `produccion` (y,
   si se quiere, exigirle revisores para que el despliegue a `main` espere
   aprobación).
8. **Probar el push de verdad** con un navegador real: es lo único de CU-22 que no
   se puede cerrar en local (ver la nota de la bitácora sobre la rama de
   suscripción caducada).
