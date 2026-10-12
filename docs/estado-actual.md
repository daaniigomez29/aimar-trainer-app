# Estado actual del proyecto

Resumen operativo para retomar el trabajo. Complementa a `AGENTS.md` (convenciones)
y a `bitacora.md` (histórico cronológico): aquí está **dónde estamos, qué trampas
ya se han pisado y qué queda abierto**.

Última actualización: 2026-10-12. La app está **en producción**: Vercel sirve
la PWA, el pipeline despliega a Supabase en cada push a `dev` y a `main`, y hay
clientes reales dados de alta.

## Fases

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1 | Esqueleto, `perfiles`/`clientes`/`ejercicios`, autenticación (CU-01, CU-24) | Hecha y verificada |
| 2 | Biblioteca de ejercicios (CU-02 a CU-04) | Hecha y verificada |
| 3 | Gestión de clientes + Edge Functions reales (CU-17 a CU-19) | Hecha y verificada |
| 4 | Planificación semanal (CU-05 a CU-16) | Hecha y verificada |
| 5 | Progreso del cliente (CU-20, CU-21, medidas, check-in) | Hecha y verificada |
| 6 | Notificaciones (CU-22) | Hecha y verificada en local |
| — | Despliegue en la nube (Supabase + Vercel + CI/CD) | **Hecho y en uso** |

Verificación actual: `supabase db reset` aplica **24 migraciones** limpias,
`./scripts/probar_local.sh` da **200/200**, `flutter test` **476**,
`dart analyze --fatal-infos` sin incidencias.

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
21. **Las dependencias de las Edge Functions van con `npm:` y versión en el
    propio `import`**, no por el import map. Es justo lo contrario de lo que
    pide `deno lint`, cuya regla `no-import-prefix` está desactivada en
    `supabase/functions/deno.json` por eso. El motivo:
    `supabase functions deploy --use-api` sube **solo los `.ts`** de cada
    función y empaqueta en el servidor, donde `deno.json` no existe; con un
    nombre a secas el despliegue falla con un 400 (*Relative import path
    "@supabase/supabase-js" not prefixed with / or ./ or ../*) mientras
    `deno check` pasa en verde, porque a él sí se le pasa la configuración.
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
25. **Un `if` por valor de enum no es exhaustivo, y nadie avisa.** Las dos
    comprobaciones de la exclusión series/minutos preguntaban `if v_tipo =
    'cardio'` y `if v_tipo = 'fuerza'`, sin rama por defecto. Al añadir
    `fortalecimiento` al enum, un ejercicio de ese tipo no entraba en ninguna de
    las dos: el trigger le habría dejado tener **minutos y series a la vez**, y
    la RPC de registro habría descartado `p_minutos` en silencio. En Dart el
    mismo problema iba al revés y era peor: `esCardio ? minutos : series`
    **compila sin una sola queja** y convierte el tipo nuevo en Fuerza sin que
    nadie lo decida (20 sitios en 8 archivos). Se arregla preguntando por el
    **modo de planificación** (`planifica_con_minutos()` en SQL,
    `TipoEjercicio.modo` en Dart), que es `if/else` sin hueco y falla en voz
    alta ante un tipo que no haya pasado por ahí.
26. **La ventana oculta congela Flutter web.** Con la ventana de Claude
    minimizada o detrás de otra, el navegador deja de servir
    `requestAnimationFrame`, y como Flutter procesa los eventos de puntero
    dentro del frame, el lienzo ni pinta ni reacciona: las capturas expiran y
    los clics no llegan. El texto **sí** entra (va al `<input>` oculto del DOM),
    lo que despista. Para comprobar en el navegador hay que tener la ventana
    delante; el árbol de accesibilidad se activa pulsando
    `flt-semantics-placeholder`.
27. **Un `AppBar` dentro de un `Column` necesita altura acotada.** En
    escritorio, `PantallaEntrenador` mete la cabecera en una columna (la barra
    lateral llega hasta arriba, así que no puede ir como `appBar` del
    `Scaffold`). Ahí recibe alto **sin acotar**, y una cabecera con `bottom`
    —la de Plannings lleva el nombre del cliente debajo— revienta el layout con
    "RenderFlex children have non-zero flex but incoming height constraints are
    unbounded" y deja la pantalla en blanco: desde fuera parece que la app se
    cuelga. Va envuelta en un `SizedBox` con su `preferredSize.height`, que ya
    cuenta el `bottom`.
28. **Meter "hoy" en el dominio vuelve los tests dependientes de la fecha.**
    Desde que `esEditable` mira si la semana ya pasó, un planning de prueba con
    fecha fija deja de ser editable en cuanto llega el lunes siguiente: los
    tests de edición empezarían a fallar solos una noche cualquiera, sin que
    nadie toque el código. `planningDePrueba` calcula su semana con
    `Semana.deHoy()` en vez de fijarla, y ningún test de edición puede volver a
    poner una fecha del pasado.
29. **El `and` de SQL no garantiza cortocircuito.** Un trigger compartido por
    varias tablas que haga
    `if tg_table_name = 'sesiones' and new.planning_id ...` se evalúa entero
    para las demás y revienta con `42703`, *record "new" has no field*. Hay que
    anidar los `if`. Lo mismo con `coalesce(new, old)`: sobre registros pierde
    el tipo y los accesos a campos fallan con `22P02`. Costó ver porque el
    error aparecía en comprobaciones que no tenían nada que ver con la regla
    nueva.
30. **Encadenar pantallas con `context.go` reutiliza su `State`.** Al pasar de
    un ejercicio al siguiente, el widget ocupa el mismo sitio del arbol, asi
    que Flutter **no crea un `State` nuevo**: solo le cambia el `widget`. Lo
    que se inicializa en `initState` (controladores de texto, mapas) se queda
    con los datos del anterior. Se vio como una mezcla —las series de un
    ejercicio con el plan de otro— y como una pantalla roja al venir de un
    cardio, que no crea ninguna serie y dejaba el mapa vacio. Dos defensas: el
    enrutador pone `key: ValueKey(ejercicio.id)`, y la pantalla rehace sus
    campos en `didUpdateWidget` cuando cambia el id.
31. **`deno check` solo miraba dos de las tres funciones.** `enviar-recordatorios`
    se añadió en la fase 6 y no se incluyó en el paso del CI, así que su código no
    pasaba por el comprobador de tipos. Ya están las tres.
32. **Los enlaces de correo de Auth son de un solo uso, y su fallo no llega como
    evento.** GoTrue borra el token al canjearlo: pinchar dos veces el enlace de
    invitación no puede funcionar. Al segundo intento redirige a la app con
    `#error=access_denied&error_code=otp_expired`, y el SDK reporta eso como
    **error del stream** de `onAuthStateChange` (`notifyException`), no como
    evento. `ControladorSesion` escuchaba sin `onError`, así que el estado no se
    movía de `SesionDesconocida` y el enrutador aparcaba en la pantalla de carga:
    spinner infinito y un cliente sin forma de fijar su contraseña (2026-10-12).
    Tres defensas: `onError`, leer el error de la URL de arranque
    (`errorDeEnlaceDeCorreo`) y un tope de espera en la consulta del perfil.
33. **Un `Timer` vivo dentro de un provider revienta 75 tests de widget.**
    `_verifyInvariants` de `flutter_test` falla con `!timersPending` si al
    terminar el test queda alguno pendiente, y un `keepAlive` que arranca un
    temporizador de 8 s en su `build` lo deja en **todos** los tests que montan
    la app. Un tope de espera va en la petición (`Future.timeout`, que se cancela
    al completarse), no en un temporizador suelto.
34. **Los correos de Auth no los manda Resend por su API, sino el SMTP del
    proyecto.** `resetPasswordForEmail` lo envía GoTrue; las invitaciones y los
    recordatorios los manda una Edge Function con la API de Resend. Sin SMTP
    propio configurado en el panel, la recuperación sale del servicio integrado
    de Supabase: remitente de Supabase, límite de 2 correos/hora y pensado solo
    para pruebas. Resuelto el 2026-10-12 poniendo Resend como SMTP de Auth
    (`smtp.resend.com`, usuario `resend`, clave la API key, remitente del dominio
    verificado).

## Decisiones tomadas (no reabrir sin motivo)

- **CU-24 mantiene el mensaje genérico** cuando el correo no está registrado: no se
  confirma si una cuenta existe. Decisión confirmada explícitamente. De ahí que
  pedir un enlace sea un **campo de correo libre**, también en la pantalla donde
  aterriza un enlace gastado: el enlace va al buzón de su dueño, así que poner el
  correo de otra persona no da acceso a nada; lo único que se arriesga es
  mandarle un correo que no ha pedido, y de eso se encarga el límite de envíos de
  GoTrue. No se añade superficie nueva: ese mismo campo ya era público en
  `/recuperar-contrasena`, a un clic del login.
- **`/restablecer-contrasena` es ruta pública** (2026-10-12). Es donde aterriza el
  enlace del correo, y ese enlace puede llegar ya gastado: sin sesión, esa
  pantalla es la que lo explica y ofrece pedir otro. Mandar al login a un cliente
  invitado lo dejaba sin salida, porque allí no tiene ninguna contraseña que
  escribir. No abre nada: fijar la contraseña sigue exigiendo la sesión del
  enlace, y sin ella `establecerNuevaContrasena` responde `ErrorEnlaceCaducado`.
- **"Lo pasado no se toca" se aplica boton a boton, y hay que repasarlos todos**
  (2026-10-12). La regla vive en `PlanningSemanal.esEditable`, pero cada accion
  de la pantalla tiene que consultarla por su cuenta, asi que olvidarse de una
  no da ningun error: deja un boton que invita a algo imposible. Se quedaron dos
  sin gatear hasta que se vieron en uso: **copiar lo que hizo el cliente a lo
  planificado** (rellenaba los campos y luego no habia donde guardar) y
  **"Añadir ejercicio"** de un bloque (abria el formulario de algo que el
  trigger iba a rechazar). El criterio es **deshabilitar, no esconder**, con el
  motivo en el tooltip cuando quepa: un boton que desaparece se lee como que la
  funcion no existe. Lo vigila `editor_semana_pasada_test.dart`.
- **El filtro por tipo y el muscular se cruzan, no se sustituyen** (2026-10-12).
  Pulsar "Fortalecimiento" y "Hombro" da los ejercicios de fortalecimiento de
  hombro, que es justo la consulta útil para un cliente lesionado. Se barajo
  hacerlos excluyentes para que la combinacion no diera nunca una lista vacia,
  y se descarto: la lista vacia ya se explica sola y ofrece "Quitar filtros".
  Solo se ofrecen los chips de Cardio y Fortalecimiento: Fuerza es la mayor
  parte de la biblioteca y los grupos musculares ya sirven para recorrerla.
- **Un ejercicio de series nace con 3x8** (2026-10-12), y cada serie añadida
  hereda peso, repeticiones y RIR de la anterior. Las constantes viven en el
  dominio (`seriesPorDefecto`, `repeticionesPorDefecto`), no en la pantalla:
  es una regla de planificacion. Al **editar** no se toca nada, se ensena lo
  guardado.
- **El cliente entra siempre por la semana en curso** (2026-10-12). Si no tiene
  planning de esta semana se le ensena la semana vacia, no el planning mas
  cercano: antes se caia en el mas reciente de la lista, que llega ordenada por
  fecha descendente, y el cliente abria la app directamente en la semana que
  viene en cuanto el entrenador se la dejaba montada.
- **La invitación manda sobre el tipo de enlace** (2026-10-12). Un cliente
  invitado rescatado con un enlace de **recuperación** sigue sin tener
  contraseña, así que el estado lo decide el metadato `debe_fijar_contrasena` y no
  el evento `passwordRecovery`. Si no, la pantalla le hablaba de "contraseña
  nueva" y le ofrecía "Volver al acceso", que para él no lleva a ninguna parte.
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
- **Las Edge Functions van con `verify_jwt = false`** (2026-10-06), y no es que
  no se compruebe el token: lo valida la propia función, que además exige el rol
  (el rol la plataforma no lo mira). El motivo es el preflight: el navegador manda
  un `OPTIONS` **sin** `Authorization`, así que con la verificación de la
  plataforma activada ese preflight se rechaza antes de llegar al código y el
  navegador lo reporta como un error de CORS que no lo es.
- **`APP_BASE_URL` admite varios orígenes separados por comas** (2026-10-06):
  la app vive en el dominio de Vercel y en el propio. `Access-Control-Allow-Origin`
  no admite listas, así que la función mira el `Origin` de cada petición y
  devuelve ese, con `Vary: Origin`. Un origen desconocido recibe el primero de la
  lista, que no coincide con el suyo, y el navegador lo bloquea. Para los
  **enlaces de los correos** se usa siempre el primero, que es el canónico.
- **Toda la navegación va por rutas de go_router** (2026-10-06): no queda ni un
  `Navigator.push` imperativo. El motivo fue un fallo real: en web ese `push` no
  deja entrada en el historial, así que el botón atrás del navegador (y el gesto
  atrás del móvil) retrocedía a la última ruta visitada —la planificación o los
  ajustes— en vez de a la pantalla anterior.
- **Se navega con `context.go`, no con `context.push`.** `push` apila sin tocar
  la URL del navegador, así que mantiene el mismo fallo; se comprobó en la app ya
  convertida, donde la URL seguía sin cambiar. Con `go` la URL refleja dónde
  estás, el atrás funciona y se puede **recargar sin perder el sitio**. Que la
  flecha de la cabecera siga volviendo donde toca lo da la **jerarquía**: cada
  pantalla se declara como ruta hija de aquella desde la que se abre.
- **Lo que no cabe en una URL se resuelve desde el planning**: el bloque, la
  sesión y el ejercicio planificado llegan como `id` y los busca
  `ResolverDelPlanning`, que carga el planning completo (lo que la pantalla iba a
  hacer igualmente) y avisa si eso ya no existe.
- **Añadir y editar un ejercicio del bloque son rutas hermanas**, no una dentro
  de otra: anidadas, al guardar la edición (o al pulsar atrás) el entrenador
  acababa en un formulario de "Añadir ejercicio" vacío en lugar de volver al
  planning.
- **Las series se añaden y se quitan en el formulario del ejercicio**, no en la
  cuadrícula de la planificación, que solo edita los valores de las series que ya
  existen. Por eso cada ejercicio tiene botón de editar junto a la X. La
  cuadrícula se rehace (`didUpdateWidget`) cuando las series cambian por detrás y
  olvida lo que tuviera sin guardar de ese ejercicio: si no, "Guardar cambios"
  escribiría lo viejo encima de lo que se acaba de guardar en el formulario.
- **Toda pantalla con sesión lleva su barra de navegación** (`PantallaConNavegacion`):
  la pantalla declara en qué **sección** está, no la ruta, porque la misma
  pantalla cuelga de destinos distintos según el rol. Solo las de autenticación
  se quedan sin barra.
- **La flecha de atrás respeta de dónde se vino**, no el padre de la ruta: con
  rutas anidadas, `context.go` monta la pila entera y el padre puede ser una
  pantalla por la que nadie pasó. Quien navega lo deja dicho con
  `Rutas.conVuelta`, que viaja como `?volver=` en la URL para sobrevivir a una
  recarga.
- **La descripción de un ejercicio es opcional** y se guarda como cadena vacía:
  la columna sigue siendo `not null` y no merecía una migración.
- **El planning es de una semana, no de un día** (`domain/semana.dart`): la
  navegación, el calendario y el formulario hablan de `Semana`, y cualquier día
  que se elija en un calendario se resuelve a su semana de lunes a domingo. Antes
  el cálculo del lunes estaba repetido en dos pantallas.
- **La vista del cliente se refresca sola por dos vías** y no por una: Realtime
  sobre `plannings_semanales` para lo que aparece y desaparece (necesita
  `replica identity full`, o el DELETE no llega: el WAL solo lleva la clave
  primaria y Realtime no puede comprobar ni el filtro ni la RLS), y una recarga
  al recuperar el foco para el socket caído y para los cambios de dentro del
  planning, que no viajan por Realtime.
- **La app es solo en español, sin negociar con el sistema**: `flutter_localizations`
  más `locale: Locale('es')` fijo. Además de traducir los `DatePicker`, hace que
  la semana del calendario empiece en lunes, que es como se planifica aquí.
- **El vídeo incrustado nace inerte** (`pointer-events: none`) y se activa al
  tocarlo: un iframe se queda la rueda y el dedo, y como Flutter desplaza
  escuchando esos eventos, encima del vídeo no había scroll. El aviso de "toca
  para activar" se pinta en el DOM porque una vista de plataforma va **por
  encima** del lienzo: lo que pinte Flutter ahí queda debajo del vídeo. El
  contenedor del iframe también tiene que ser inerte, o es él quien queda bajo
  el puntero.
- **Las listas de plannings las recarga el controlador**, no las pantallas:
  crear, editar, archivar, reactivar y eliminar invalidan la familia entera.
  Repartido por pantallas siempre se olvidaba alguna.
- **La clasificación muscular tiene dos niveles y el grupo no se guarda**
  (2026-10-09): `GrupoMuscular` (6) y `Musculo` (21), y cada músculo sabe su
  grupo, así que el del ejercicio **se deriva** del músculo principal. Guardar
  los dos permitiría el estado "grupo: Pecho / principal: Cuádriceps", que no
  detectaría nadie hasta que el filtro mintiera; hay un `check` que lo impide.
  La columna `grupo_muscular` solo se rellena cuando **no** hay principal, que
  es el caso del cardio.
- **Los tres campos musculares son opcionales**: la cinta de correr es de Pierna
  sin músculo concreto, y un ejercicio de fortalecimiento puede querer declarar
  solo la zona. Lo que queda sin clasificar no se esconde: tiene su propia
  pestaña en la biblioteca para que el entrenador lo complete.
- **Al filtrar, los secundarios cuentan**, pero el orden los distingue: primero
  los que tienen ese músculo como principal, detrás los demás, con la marca
  "secundario". Si no contaran, declararlos solo serviría para mirar la ficha;
  si no se distinguieran, "ejercicios de glúteo" y "ejercicios que además usan
  el glúteo" se mezclarían.
- **La taxonomía es un enum de Postgres y una lista fija en Dart**, no un
  catálogo editable: para un solo entrenador no compensa la tabla, la RLS y el
  repositorio. Añadir un músculo es una migración de una línea
  (`alter type musculo add value`) más un valor en el enum; **quitarlo o
  renombrarlo obliga a recrear el tipo**, así que la lista se pensó una vez.
- **Los músculos se parsean con conversores escritos a mano**
  (`ConversorMusculo`, `ConversorMusculos`): lo que genera `@JsonEnum` lanza
  ante un valor que no conoce, y eso tumbaría el parseo de **toda** la
  biblioteca —no solo de esa fila— el día que una migración añada un músculo
  antes de que se despliegue la app. Así un valor desconocido se descarta y el
  ejercicio aparece sin clasificar.
- **El texto libre anterior se renombró, no se convirtió**: `grupo_muscular`
  pasó a `grupo_muscular_antiguo` y la columna nueva estrenó el nombre bueno. Un
  `using` con mapeo habría perdido en silencio los valores no contemplados; así
  siguen consultables para reclasificar a mano. Se elimina en otra migración
  cuando no quede nada sin clasificar.
- **Fortalecimiento se planifica como Fuerza** (2026-10-09): series y
  repeticiones, con el peso y el RIR vacíos cuando es peso corporal o goma
  (`series_planificadas` ya los tenía nulables). Planificar fortalecimiento
  **por tiempo** (isometrías) no cabe en el modelo: haría falta `segundos` en la
  serie, y queda como pendiente aparte.
- **Lo que decide series o minutos es el modo, no el tipo**
  (`ModoPlanificacion`, `planifica_con_minutos()`): ver la trampa 25.
- **El color y el icono de cada tipo viven en un solo sitio**
  (`EstiloTipoEjercicio`, en `presentation`): estaban repetidos como ternarios
  en la miniatura, la tarjeta y el formulario, y los tres daban por hecho que
  solo había dos tipos. Mismo motivo que `MiniaturaEjercicio`.
- **El filtro muscular se pliega en dos niveles** (2026-10-09): en el formulario
  del ejercicio y al elegir uno para un bloque, los músculos viven dentro de un
  desplegable por grupo, y ese bloque entero dentro de otro. Pintados de golpe
  son 21 chips, que es volver a la lista interminable que esto venía a quitar.
  De partida solo se ve el buscador y una línea que dice por qué se está
  filtrando.
- **Los dos sitios desde los que se añade un ejercicio comparten filtro**
  (`FiltroDeEjercicios`, sobre `filtroBibliotecaProvider`): el panel lateral del
  planning y el formulario de CU-08, que antes tenía un desplegable con la
  biblioteca entera dentro. El widget **es dueño de su campo de búsqueda** y lo
  arranca con lo que el filtro ya tenga: con un controlador vacío, la lista
  saldría recortada por un texto que no se ve en ninguna parte.
- **Con un ejercicio ya elegido, el formulario de CU-08 retira la lista** y deja
  lo elegido más un botón de cambiar: al editar, lo que importa de esa pantalla
  son las series, no volver a buscar el ejercicio.
- **El "+" del panel pregunta a qué bloque va** cuando la sesión tiene más de
  uno (2026-10-09). Antes caía siempre en el primero, y una sesión de
  calentamiento más fuerza es justo el caso en el que eso nunca es lo que se
  quiere. Con un solo bloque no se pregunta: sería un clic sin decisión detrás.
- **Cada pantalla filtra la biblioteca por su cuenta** (`AmbitoDeFiltro`:
  biblioteca, panel del planning y formulario de bloque). Compartían estado, así
  que buscar "sent" en una dejaba la otra enseñando solo la sentadilla, **sin
  nada escrito en su buscador** que lo explicara. Tampoco lo comparten las dos
  que sirven para lo mismo: el panel y el formulario pueden verse en el mismo
  recorrido, y que uno herede el filtro del otro se lee como que la pantalla
  está rota, no como una comodidad.
- **"Todo el grupo" suelta el músculo** (`verTodoElGrupo`): con cuádriceps
  elegido, pulsarlo no hacía nada visible, porque `cambiarGrupo` conserva el
  músculo si es de ese mismo grupo y el chip se quedaba sin marcar.
- **El cliente puede quitar la serie de más que acaba de añadir**, no las
  planificadas (las pone el entrenador) ni una que ya haya confirmado:
  `series_realizadas` no tiene `delete` a propósito, así que ofrecerlo sería
  prometer algo que la base de datos no deja hacer. Y solo la última, para no
  dejar huecos en la numeración.
- **"Guardar y siguiente ejercicio" guarda**, no solo navega: el check verde de
  cada serie sigue estando, pero no puede ser la única forma de guardar. El
  cliente rellena, pulsa el botón de abajo y da por hecho que con eso vale.
- **Duplicar una semana se hace "hacia aquí"** (2026-10-11): el entrenador se
  pone en la semana que quiere montar y elige de qué planning traerla, en vez
  de ir al origen y elegir destino. Es el recorrido real —estás preparando la
  semana que viene, no visitando la pasada— y te deja ya donde quieres ver el
  resultado. El origen se elige de la **lista de plannings del cliente**, no de
  un calendario: un calendario deja señalar semanas vacías y el error solo se
  vería después de copiar. Entran también los archivados, que es el histórico
  que interesa reutilizar.
- **La copia es del plan, nunca de lo realizado**: ni `series_realizadas`, ni
  `minutos_realizados`, ni `estado_registro`, ni `fecha_realizada`, ni
  `resultado_registrado`. Si se copiara, el histórico y las gráficas de CU-21
  contarían entrenamientos que no existieron.
- **Los ejercicios dados de baja se quedan fuera**, y la función devuelve
  cuántos para que la app lo diga. La regla de dominio es que un ejercicio
  eliminado no se añade a bloques nuevos, y duplicar es añadirlo; omitirlos en
  silencio dejaría bloques con menos ejercicios sin explicación. Al omitir uno
  se **renumera** el bloque: copiar el orden original dejaría huecos (1 y 3), y
  la app calcula la siguiente posición como "cuantos hay + 1", que chocaría con
  el índice único.
- **Solo se duplica sobre una semana vacía**: un planning activo por cliente y
  semana lo impone el índice único, así que el botón se deshabilita con el
  motivo en lugar de prometer algo que la base de datos va a rechazar.
- **Lo pasado no se toca** (2026-10-11): el entrenador no crea, modifica, borra
  ni duplica semanas terminadas. Vive en triggers y no en políticas RLS por la
  trampa 8: un `update` bloqueado por RLS no da error, deja 0 filas y la app lo
  traduciría a "eso ya no existe", que no explica nada. Tres exenciones, cada
  una por su motivo: solo aplica al entrenador (si no, el seed, que mete
  semanas pasadas, no arrancaría), el cliente sigue registrando lo que hizo, y
  archivar sigue permitido porque no cambia el plan.
- **El interruptor es `PlanningSemanal.esEditable`**, que ya existía para los
  archivados. En el editor del entrenador había 14 puntos de escritura y solo
  2 lo miraban: allí el planning siempre estaba activo y la comprobación era
  código muerto. Ahora lo miran todos, incluidas las celdas de la cuadrícula,
  que si no dejarían teclear algo que el botón de guardar, apagado, no podría
  guardar.
- **Borrar el planning también desde el editor**: es donde se cometen los
  errores que hay que deshacer (crear la semana sin querer, duplicar del origen
  equivocado). Antes solo estaba en la ficha del cliente.
- **Al crear un día, el entrenador se va a ese día** (`pedirDatosSesion`
  devuelve la sesión guardada en vez de un `bool`): se añade el Día 3 para
  montarlo, no para seguir mirando el Día 1. Editar uno existente no cambia de
  día. Es lo contrario que en el cliente, y a propósito: uno viene a trabajar
  lo que acaba de crear, el otro acaba de terminar lo que estaba haciendo.
- **Al terminar un día, el cliente se queda en ese día**: el inicio abre por la
  primera sesión sin terminar, que justo después de acabar es la siguiente, así
  que lo recién hecho desaparecía de la vista. Se vuelve con `?dia=N` y el
  parámetro lo **inyecta el enrutador**, no lo lee la pantalla: con
  `GoRouterState.of` dentro, la pantalla deja de poder montarse sin un
  `GoRouter` encima (y en esta versión de go_router no hay `maybeOf`).
- **Medidas y check-in no comparten guardado**: dos formularios, dos botones, dos
  operaciones. Es lo que dice el modelo de dominio, no una limitación.

## Pendientes abiertos

Decisiones que quedaron sin cerrar:

- **Peso "por lado" vs. total (pedido el 2026-10-09, sin empezar).** El entrenador
  quiere marcar que el peso de una serie es por lado, para que al cliente le
  aparezca `Plan: 9 kg por lado × 8`. Propuesta sobre la mesa, a falta de dos
  decisiones suyas:
  1. ¿El **cliente** también lo marca al registrar lo que hizo? (Recomendado sí,
     heredando lo que puso el entrenador: lo planificado y lo realizado son
     independientes, y hoy no podría decir que lo hizo con otro reparto.)
  2. ¿Checkbox **por serie** o uno por ejercicio que las marque todas?
  Lo decidido del diseño: la marca va en `series_planificadas` (y en
  `series_realizadas` si entra lo del cliente), como `boolean peso_por_lado not
  null default false`; **es una etiqueta, no una operación** —el peso se guarda
  tal cual, no se multiplica, o el histórico y las gráficas dejarían de ser
  comparables con lo ya registrado. Implica migración y toca el dominio, así que
  no se empieza sin su visto bueno.
- **Guardas de `dar-de-baja-cliente` (incidente del 2026-10-07, sin aplicar).** La
  cuenta del entrenador acabó baneada en producción porque **tiene ficha en
  `clientes`**: `clientes.id` ES el id de Auth, la función banea ese id y solo
  comprueba que exista y esté activo —no mira el rol—, y la lista de clientes de
  la app hace `select()` sin filtrar. Así que el entrenador aparecía como un
  cliente más y darle de baja lo baneó. (El desfase horario del incidente era
  solo que **Supabase muestra UTC**: 22:50 UTC = 00:50 en España.) Propuesto y
  pendiente de aprobación: rechazar si el objetivo no tiene `rol = 'cliente'`,
  rechazar si el objetivo es quien llama, y filtrar la lista por rol. Falta
  además decidir qué se hace con esa fila de `clientes` del entrenador.
- **`RESEND_FROM_EMAIL` tiene que ser un buzón del dominio verificado**
  (`mail.aimartrainer.es`, no `aimartrainer.es`): estaba puesto el dominio a
  secas y Resend devolvía `validation_error` 422. El valor correcto es del tipo
  `Aimar Trainer <no-reply@mail.aimartrainer.es>`. No hace falta redesplegar: los
  secretos se leen en cada ejecución.
- **Bucket de Storage** de las fotos de progreso: `fotos-progreso` está declarado
  en `config.toml`, creado y verificado en local (privado, 20 MiB, png/jpeg), con
  sus políticas en la migración
  `20261003090200_politicas_storage_fotos_progreso.sql`, y **ya creado también en
  la nube**. El detalle está en `architecture.md`, sección "Almacenamiento de
  ficheros". Nada pendiente.
- **Resend ya tiene dominio verificado** (`mail.aimartrainer.es`) y las dos
  variables puestas en la nube. En local las invitaciones se siguen entregando en
  Mailpit vía `CORREO_DEV_URL`.
- **Reactivar un cliente dado de baja**: hoy no se puede volver a darlo de alta con el
  mismo correo (Auth no admite duplicados, aunque el índice de `clientes` sí lo
  permita entre bajas). Devuelve 409 con un mensaje que lo explica. No es un caso de
  uso del ERS; queda por decidir si se añade.
- **Comprobar en el navegador** lo de 2026-10-09 (taxonomía, Fortalecimiento,
  filtro plegable y elección de bloque): sigue sin hacerse. La app arranca y
  pinta (218 frames en 1,5 s), pero **los clics no llegan al lienzo**: ni por
  coordenadas (el marco del panel va a 800×450 mientras el viewport es
  1280×720) ni pulsando los nodos de accesibilidad desde JavaScript. El texto sí
  entra, porque va al `<input>` oculto del DOM. Verificado por otras vías: 184
  comprobaciones del script contra Supabase local y 406 tests. Falta verlo con
  los ojos.
- **Fortalecimiento por tiempo**: si Aimar quiere planificar isometrías
  (plancha 30 s), hace falta `segundos` en la serie. No cabe en el modelo actual
  y se dejó fuera a propósito.
- **`requirements.md` sigue diciendo "grupo muscular"** en RF-02 y en la
  secuencia de CU-02, donde el formulario pide ahora grupo, músculo principal y
  secundarios. El ERS completo (Doc del proyecto) necesita el mismo retoque; no
  se ha tocado sin decidirlo.
- **Reclasificar lo que quede en `grupo_muscular_antiguo`** en la nube cuando se
  despliegue: la migración mapea los valores conocidos y deja el resto sin
  clasificar a propósito, visible en su chip.
- **Anotar en `AGENTS.md`** la regla de migraciones inmutables (trampa 7).
- **`linguist-generated=true`** en `.gitattributes` oculta los `.g.dart` en los diffs
  de GitHub y los excluye de las estadísticas de lenguaje. Si para el TFG interesa que
  cuenten, hay que quitar esas dos líneas.
- **`docs/sql-schema.md`** usa `auth.role() = 'authenticated'` en la política de
  lectura de `ejercicios`; las migraciones usan `to authenticated`. Ambos funcionan en
  una petición normal, pero `auth.role()` devuelve `NULL` si la sesión no trae los
  claims. Queda por unificar doc y código.

## Despliegue: en producción y funcionando

Las seis fases del ERS están implementadas, y la aplicación **está desplegada y
en uso**: Vercel sirve la PWA, el pipeline aplica migraciones y publica Edge
Functions, y hay clientes reales dados de alta que reciben su invitación y
entran. Lo que queda abierto está al final de esta sección y es poco.

El **pipeline**: el job `desplegar` de `.github/workflows/ci.yml`
aplica las migraciones (`supabase db push`) y publica las Edge Functions
(`supabase functions deploy`) en cada push a `dev` y a `main`, después de que
pasen análisis, tests y las comprobaciones de Deno. El proyecto al que va lo
decide el **Environment** de GitHub, que se llama como la rama (`main`, `dev`),
porque los secretos son suyos. Mientras un entorno no tenga secretos, el job se
salta solo y lo dice en el resumen, en vez de poner la rama en rojo. **`main` y
`dev` ya los tienen**, así que ahí el job despliega de verdad.

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

Ya en marcha y comprobado en producción:

- **Environments `main` y `dev`** con sus tres secretos, apuntando al proyecto
  `app-aimar-trainer-dev` (ref `aihlqyyeqrybhrawxkut`, eu-west-1). El job
  `desplegar` corre de verdad en los dos.
- **Vercel** sirve la PWA. La configuración vive en `vercel.json`, que apunta a
  dos scripts (`scripts/vercel_install.sh` instala el SDK de Flutter 3.47.5;
  `scripts/vercel_build.sh` compila con los `--dart-define` leídos de las
  variables de entorno) y publica `build/web`. Los comandos van en scripts porque
  el schema de Vercel **no admite más de 256 caracteres** en `installCommand` ni
  en `buildCommand`.
- **Secretos de las Edge Functions** puestos: las invitaciones salen desde el
  dominio propio con Resend y los enlaces vuelven a la app, así que
  `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `APP_BASE_URL` están bien, y las
  *Redirect URLs* de Auth también.
- **Resend con dominio verificado** (`mail.aimartrainer.es`), por API para las
  invitaciones y como **SMTP de Auth** para la recuperación (ver trampa 34).
- **Altas de clientes reales** funcionando de punta a punta: `crear-cliente`,
  correo, elección de contraseña y entrada a la app.
- **Los dos secretos de Vault** del job de recordatorios y `SECRETO_CRON` en las
  funciones, con el mismo valor. La migración crea `pg_cron`, `pg_net` y la
  función que los lee; los valores se pusieron a mano, que es lo correcto: no
  tienen por qué pasar por un log de CI.
- **Par VAPID propio de producción**: `VAPID_PUBLIC_KEY` en Vercel y la privada
  en las Edge Functions. El de local no valía.
- **Buckets `fotos-progreso` e `imagenes-ejercicios`** creados en el panel. Sus
  políticas viajan en migración; los buckets en sí los crea `config.toml`, que es
  cosa de local, por eso había que crearlos a mano en la nube.
- **La integración de GitHub del panel de Supabase, desconectada**. Aplicaba
  migraciones por su cuenta sin mirar el CI; con las dos activas cada push
  desplegaba dos veces. Ahora el despliegue lo lleva solo Actions.

La puesta en producción **está cerrada**. Lo único que sigue abierto:

1. **Probar el push de verdad** con un navegador real: es lo único de CU-22 que
   no se puede cerrar en local (ver la nota de la bitácora sobre la rama de
   suscripción caducada). Con el par VAPID de producción ya puesto, se puede
   hacer cuando se quiera.
2. **Comprobar que el recordatorio llega**: el job de `pg_cron` ya tiene sus
   secretos, pero si algo no cuadrara fallaría **en silencio** (se dispara y no
   llega a ninguna parte). La señal de que va bien es que un cliente reciba el
   correo de "empieza una semana nueva" el día que arranca su planning.
3. **Proyecto aparte para pruebas** (opcional): crearlo, rellenar un Environment
   propio y, si se quiere, exigirle revisores para que el despliegue a `main`
   espere aprobación.
