# Estado actual del proyecto

Resumen operativo para retomar el trabajo. Complementa a `AGENTS.md` (convenciones)
y a `bitacora.md` (histórico cronológico): aquí está **dónde estamos, qué trampas
ya se han pisado y qué queda abierto**.

Última actualización: 2026-10-02, con el acceso del cliente a su planning ya hecho,
justo antes de empezar la fase 5.

## Fases

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1 | Esqueleto, `perfiles`/`clientes`/`ejercicios`, autenticación (CU-01, CU-24) | Hecha y verificada |
| 2 | Biblioteca de ejercicios (CU-02 a CU-04) | Hecha y verificada |
| 3 | Gestión de clientes + Edge Functions reales (CU-17 a CU-19) | Hecha y verificada |
| 4 | Planificación semanal (CU-05 a CU-16) | Hecha y verificada |
| 5 | Progreso del cliente (CU-20, CU-21, medidas, check-in) | **Siguiente** |
| 6 | Notificaciones (CU-22) y despliegue | Pendiente |

Verificación al cerrar la fase 4: `supabase db reset` aplica 8 migraciones limpias,
`./scripts/probar_local.sh` da **89/89**, `flutter test` **223**,
`dart analyze --fatal-infos` sin incidencias, `deno fmt`/`lint`/`check` en verde.

## Cómo arrancar el entorno

Hacen falta **dos terminales** más la app:

```bash
supabase start                            # necesita Docker Desktop abierto
supabase db reset                         # migraciones + seed
```

```bash
supabase functions serve --no-verify-jwt  # imprescindible para alta/baja de clientes
```

```bash
./scripts/run_dev.sh                      # o F5 en VS Code
```

Cuentas de prueba y contraseña: al principio de `supabase/seed.sql`. Correo de
pruebas: Mailpit en <http://127.0.0.1:54324>.

`./scripts/probar_local.sh` verifica 89 cosas por la API REST. **Requiere partir de
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
- **El vídeo de ejemplo se copia al portapapeles**, no se abre: abrirlo necesitaría
  `url_launcher`, dependencia nueva sin acordar.
- La vista del planning es **la misma pantalla para entrenador y cliente**, con
  `puedeEditar: false` para el segundo. Un planning archivado tampoco es editable.

## Pendientes abiertos

Decisiones que quedaron sin cerrar:

- **Bucket de Storage** de las fotos de progreso: `fotos-progreso` ya está
  declarado en `config.toml` y **creado y verificado en local** (privado, 20 MiB,
  png/jpeg). Falta crearlo en la nube cuando haya proyecto, y escribir sus
  políticas sobre `storage.objects`. El detalle está en `architecture.md`, sección
  "Almacenamiento de ficheros".
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

## Para la fase 5

1. **Los triggers de recálculo ya están hechos y verificados** (`estado_registro` y
   `resultado_registrado`), incluido el caso de Cardio que el `sql-schema.md` dejaba
   pendiente. CU-20 ya tiene la base de datos preparada.
2. `series_realizadas` **ya existe** con sus políticas del cliente: falta solo la
   interfaz y la lógica de escritura. Sin `delete` a propósito (lo registrado es
   histórico, se corrige con `update`).
3. Faltan las migraciones de `registros_medidas`, `fotos_progreso` y
   `checkins_recuperacion`, que están definidas en `sql-schema.md`.
4. **El administrador no debe tener acceso** a medidas, fotos ni check-in: se consigue
   por ausencia de política RLS, no creando ninguna. Hay un widget test que fija que
   tampoco ve las fichas de clientes.
5. Para CU-20, el patrón de la RPC atómica de la fase 4 sirve igual: registrar varias
   series realizadas de una sesión debería ir en una sola transacción.
6. **El acceso del cliente a su planning ya está hecho** (`/cliente/planning`,
   `PantallaMisPlannings`), de solo lectura y reutilizando `PantallaPlanning`. Es
   desde ahí desde donde colgará el registro de resultado de sesión: el cliente abre
   la semana, entra en la sesión del día y registra. `misPlannings` toma el id de la
   sesión, no por parámetro, y conviene seguir ese patrón en las pantallas de
   medidas y check-in.
7. La pantalla de **registro de serie** se hará siguiendo la captura que pasó Daniel
   (histórico de las series de sesiones anteriores arriba, e inputs de peso y
   repeticiones con botones +/− abajo), no un formulario normal.
