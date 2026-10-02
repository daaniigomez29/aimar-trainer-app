# Aimar Trainer

App de gestión de rutinas de gimnasio (Flutter Web + Supabase). Un solo
entrenador, sin registro libre de clientes.

- Convenciones y reglas de dominio: [`AGENTS.md`](AGENTS.md)
- Requisitos y casos de uso: [`docs/requirements.md`](docs/requirements.md)
- Modelo de dominio: [`docs/domain-model.md`](docs/domain-model.md)
- Arquitectura e infraestructura: [`docs/architecture.md`](docs/architecture.md)
- Esquema de base de datos: [`docs/sql-schema.md`](docs/sql-schema.md)

## Estado

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1 | Esqueleto, esquema base (`perfiles`, `clientes`, `ejercicios`), autenticación | Hecha |
| 2 | Biblioteca de ejercicios | Pendiente |
| 3 | Gestión de clientes (Edge Functions reales) | Pendiente |
| 4 | Planificación semanal | Pendiente |
| 5 | Progreso y bienestar | Pendiente |
| 6 | Notificaciones y despliegue | Pendiente |

## Puesta en marcha

```bash
flutter pub get
dart run build_runner build
```

La configuración se inyecta desde `config/`. Los archivos con valores reales
(`dev.json`, `prod.json`) están ignorados por git; las plantillas
(`dev.example.json`, `prod.example.json`) sí se versionan. La primera vez:

```bash
cp config/dev.example.json config/dev.json
```

Rellena `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`: para Supabase local salen de
`supabase status` (`API_URL` y `PUBLISHABLE_KEY`); para un proyecto de la nube, de
*Settings > API*. Después:

```bash
./scripts/run_dev.sh
```

**Desde el IDE**, la configuración de ejecución tiene que pasar ese mismo
argumento, o la app arrancará sin variables y mostrará la pantalla de
configuración incompleta. No es opcional: `--dart-define` solo llega si se pasa
en el comando.

- **VS Code**: ya está en `.vscode/launch.json` (versionado), con las
  configuraciones *Flutter (dev)*, *Flutter (dev, Chrome)* y *Flutter (prod,
  Chrome)*. VS Code solo lee las configuraciones de lanzamiento desde `.vscode/`:
  en cualquier otra carpeta se ignoran y F5 arranca `flutter run` sin argumentos.
  Como alternativa, `"dart.flutterAdditionalArgs"` en `.vscode/settings.json`
  aplica el argumento a todos los lanzamientos.
- IntelliJ / Android Studio: campo *Additional run args* de la configuración de
  Flutter, o la opción `additionalArgs` en `.idea/runConfigurations/*.xml`
  (carpeta local, no se versiona).

### Si el puerto falla con "errno 10013" en Windows

```
Failed to create server socket (OS Error: Intento de acceso a un socket no
permitido por sus permisos de acceso, errno = 10013), port = 3000
```

No significa que el puerto este ocupado, sino que **Windows lo tiene reservado**.
Hyper-V y Docker reservan bloques del rango dinamico de TCP, que aqui va de 1024 a
15000. Para ver los bloques tomados:

```bash
netsh interface ipv4 show excludedportrange protocol=tcp
```

Por eso la app usa el **54330**: esta fuera de ese rango y no puede quedar
reservado. Si alguna vez hay que cambiarlo, el puerto nuevo tiene que ir a la vez
en `scripts/run_dev.sh`, `.vscode/launch.json`, `site_url` y
`additional_redirect_urls` de `supabase/config.toml`, y `APP_BASE_URL` de
`supabase/functions/.env`; si no, los enlaces de invitacion y de recuperacion
dejaran de llegar a la app. Un cambio en `config.toml` necesita
`supabase stop && supabase start`.

Ojo: cambiar `config/dev.json` con la app ya corriendo no surte efecto con un hot
reload, porque `String.fromEnvironment` se resuelve en tiempo de compilación. Hay
que reiniciar el proceso.

`config/prod.json` es lo mismo a partir de `config/prod.example.json`, y
`./scripts/build_prod.sh` lo usa para el build de Vercel. Hoy está vacío porque el
proyecto de producción todavía no existe, así que ese script no funcionará hasta
que se cree.

Si falta `SUPABASE_URL` o `SUPABASE_PUBLISHABLE_KEY`, la app arranca en una
pantalla que lo explica en lugar de fallar con una excepción opaca.

**Nunca** pasar por `--dart-define` `SUPABASE_SERVICE_ROLE_KEY` ni
`RESEND_API_KEY`: todo lo que entra ahí queda en el bundle público.

## Comprobaciones

```bash
dart format .
dart analyze --fatal-infos
flutter test
```

**`dart analyze`, no `flutter analyze`.** `riverpod_lint` 3.x usa el sistema de
plugins nuevo del analizador (`analysis_server_plugin`) y se declara en el bloque
`plugins:` de `analysis_options.yaml`. Solo `dart analyze` carga esos plugins:
con `flutter analyze` el proyecto sale limpio pero las reglas de Riverpod no se
evalúan. `--fatal-infos` porque varias de ellas se reportan como `info`.

## Depuración

La app es deliberadamente silenciosa: los repositorios capturan toda excepción y
la convierten en un `ErrorApp` con un mensaje para la interfaz. Para que la causa
real no se pierda, `lib/core/diagnostico/` la escribe en la consola de depuración
**solo en modo debug**:

- `Registro` saca los campos que los errores de Supabase esconden y que son los
  que explican el fallo: `code`, `details` y `hint` de `PostgrestException`,
  `code` y `statusCode` de `AuthException`, `status` y `details` de
  `FunctionException`.
- `ObservadorProviders` registra los errores que viajan dentro de los providers.
  Hace falta porque un `Failure` no lanza ninguna excepción: sin él, un error que
  la interfaz muestra como un aviso amable no deja ningún rastro.
- `FlutterError.onError`, `PlatformDispatcher.onError` y una `runZonedGuarded`
  capturan lo que se escape del árbol de widgets o de un `Future` sin `catch`.

### Dónde mirar

| Sitio | Qué se ve |
| --- | --- |
| **Debug Console** de VS Code | Todo lo anterior (va por `debugPrint`) |
| **Consola del navegador** (F12) | Además, errores de JS, CORS y fallos de red |
| **Pestaña Network** (F12) | Las peticiones a Supabase con su cuerpo y su código |
| **Flutter DevTools** | Árbol de widgets, estado de providers, rendimiento |

Si la consola solo muestra el arranque (`Supabase init completed`), es que no ha
fallado nada: el registro solo escribe cuando hay algo que contar. Para
comprobar que funciona, basta provocar un fallo (parar Supabase con
`supabase stop` e intentar entrar).

Para seguir un flujo paso a paso sin depender de que falle, `Registro.info('...')`
escribe una línea suelta, y un punto de interrupción en el `case Failure` del
repositorio correspondiente detiene la ejecución justo donde se traduce el error.

## Base de datos

```bash
supabase start      # necesita Docker en marcha
supabase db reset   # recrea la BD local: migraciones + supabase/seed.sql
```

`supabase db reset` es el comando para **local**. `supabase db push` empuja a un
proyecto **remoto** vinculado y falla con `Cannot find project ref` si no se ha
hecho `supabase link --project-ref <ref>` antes; en el flujo de este proyecto no
hace falta usarlo a mano, porque las migraciones las aplica el pipeline al
integrar en `develop` y en `main`.

### Comandos locales vs. comandos contra la nube

El CLI `supabase` mezcla las dos cosas, y es la causa más común de confusión. Los
locales funcionan sin login ni vínculo; los remotos fallan con
`AccessTokenRequiredError` o `ProjectRefNotLinkedError` si falta alguno.

| Local (Docker) | Nube (necesita `login` y `link` o `--project-ref`) |
| --- | --- |
| `supabase start` / `stop` / `status` | `supabase login` |
| `supabase db reset` | `supabase link --project-ref <ref>` |
| `supabase migration up` | `supabase db push` |
| `supabase functions serve` | `supabase functions deploy` |
| | `supabase secrets set` / `list` / `unset` |

Regla práctica: **si un comando pide login o vínculo, está actuando sobre la
nube.** Los locales no lo piden nunca.

A qué entorno habla **la app** es independiente de todo esto: lo decide solo
`SUPABASE_URL` en `config/dev.json`. `supabase status` muestra el vínculo actual
en `linked_project` (`null` = ninguno).

Para aplicar solo las migraciones pendientes sin borrar los datos locales:

```bash
supabase migration up
```

### Comprobar que el entorno local está bien

```bash
./scripts/probar_local.sh
```

Verifica de punta a punta, por la API REST (el mismo camino que usa la app): el
login de las tres cuentas del seed, el rechazo de credenciales incorrectas, las
reglas RLS por rol, que no hay `DELETE` físico de clientes y la validación de rol
de las Edge Functions. Para que se incluyan estas últimas hace falta, en otra
terminal, `supabase functions serve --no-verify-jwt`; si no está arrancado, esa
sección se omite.

El script añade un par de ejercicios de prueba a la biblioteca; `supabase db
reset` vuelve a dejar solo lo del seed.

### Cuentas de prueba en local

`supabase/seed.sql` (solo local, nunca se ejecuta contra dev ni producción) crea
una cuenta de cada rol, porque el alta de entrenador y administrador se hace
desde el panel de Supabase y en local no hay panel de la nube. Los correos y la
contraseña están al principio de ese archivo.

Correo de prueba (invitaciones, recuperación de contraseña): Mailpit en
<http://127.0.0.1:54324>.

### Probar la invitación de un cliente en local (CU-17)

El cliente se crea **sin contraseña**: la elige al abrir el enlace del correo. Para
probar ese flujo completo sin tener dominio verificado en Resend:

1. `supabase/functions/.env` (cópialo de `.env.example`) con:

   ```
   CORREO_DEV_URL=http://supabase_inbucket_aimar_trainer_app:8025
   APP_BASE_URL=http://127.0.0.1:54330
   ```

   Sin `RESEND_API_KEY`, la invitación se entrega en **Mailpit**, el buzón de
   pruebas que ya trae `supabase start`. Mailpit no envía nada a internet: solo
   guarda el mensaje para poder verlo.

2. Arranca las funciones y la app:

   ```bash
   supabase functions serve --no-verify-jwt
   ```

   La app **tiene que servirse en `http://127.0.0.1:54330`** (ya lo hacen
   `run_dev.sh` y las configuraciones de `.vscode/launch.json`), porque GoTrue solo
   redirige el enlace a una URL permitida y ese es el `site_url` de
   `supabase/config.toml`.

3. Da de alta un cliente desde la app. La respuesta incluye
   `invitacionEnviada: true` y `entregadoEnBuzonLocal: true`.

4. Abre **<http://127.0.0.1:54324>**, busca el correo "Tu acceso a Aimar Trainer" y
   pulsa el enlace. La app te llevará a *Elige tu contraseña*; al guardarla, entras
   como cliente.

Para enviar de verdad, rellena `RESEND_API_KEY` y `RESEND_FROM_EMAIL` y quita
`CORREO_DEV_URL`. No hay que tocar código.

### Edge Functions en local

```bash
supabase functions serve --no-verify-jwt
```

Con `--no-verify-jwt` la comprobación del token recae en la propia función, que
es justo lo que interesa verificar. Ver `supabase/functions/README.md`.

## Estructura

```
lib/
  core/
    configuracion/   ConfiguracionApp (--dart-define)
    enrutado/        rutas y redirección por rol (go_router)
    errores/         Result<T> y ErrorApp
    plataforma/      interfaces para lo dependiente de plataforma (RNF-03)
    presentacion/    tema, widgets compartidos y pantallas principales
    supabase/        proveedores del cliente de Supabase
  features/<feature>/
    data/            repositorios Supabase (único sitio que habla con Supabase)
    domain/          entidades, reglas de dominio e interfaces de repositorio
    application/     Notifiers de Riverpod
    presentation/    pantallas y widgets
supabase/
  migrations/        esquema versionado
  functions/         Edge Functions (service_role solo aquí)
```
