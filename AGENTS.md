# AGENTS.md — App de gestión de rutinas de gimnasio (Aimar)

App para que un entrenador (Aimar) gestione planificación semanal, biblioteca de
ejercicios, fichas de cliente y métricas de progreso, sustituyendo el trabajo
manual en hojas de Excel. Un único entrenador, sin registro libre de clientes.

## Documentación ampliada

**Empieza por `docs/estado-actual.md`**: dice en qué fase está el proyecto, cómo
arrancar el entorno, las trampas ya pisadas (con su causa verificada), las
decisiones tomadas y los pendientes abiertos. Es lo que no se deduce leyendo el
código. El histórico cronológico está en `docs/bitacora.md`.

Este archivo es un resumen operativo. Antes de un cambio importante de dominio,
seguridad o infraestructura, consulta el ERS completo (Doc del proyecto), que
contiene: casos de uso y requisitos funcionales, diseño de dominio (10
entidades), diseño de infraestructura, esquema SQL completo con RLS/triggers, y
convenciones de implementación en detalle. Este `AGENTS.md` no sustituye a esos
documentos, los resume para el trabajo del día a día.

## Stack y estructura

- **App:** Flutter Web (PWA) + Riverpod (`riverpod_generator`). Android/iOS
  quedan para una fase futura; el código específico de plataforma se aísla
  tras interfaces para facilitar ese salto.
- **Backend:** Supabase (Auth, Postgres con RLS, Storage, Edge Functions,
  pg_cron), región UE.
- **Correo:** Resend (invitaciones, recuperación de contraseña, recordatorios).
- **Hosting:** Vercel (build estático de `flutter build web`).
- **CI/CD:** GitHub Actions (tests, migraciones, despliegue).
- **Estructura de `lib/`:** feature-first, con capas `data/ domain/
  application/ presentation/` dentro de cada feature (`autenticacion`,
  `biblioteca_ejercicios`, `planificacion_semanal`, `clientes`, `progreso`,
  `notificaciones`). Nada de dominio suelto en `lib/`; ninguna llamada a
  Supabase fuera de un repositorio en `data/`.
- **Backend/SQL:** `supabase/migrations/` (esquema versionado),
  `supabase/functions/` (Edge Functions).

## Comandos

- Instalar dependencias: `flutter pub get`
- Generar código (`freezed`, `json_serializable`, `riverpod_generator`):
  `dart run build_runner build --delete-conflicting-outputs`
- Analizar/lint: `dart analyze --fatal-infos` (no `flutter analyze`: solo
  `dart analyze` carga el plugin de `riverpod_lint`)
- Formatear: `dart format .`
- Tests: `flutter test`
- Build web: `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=APP_ENV=...`
- Supabase local: `supabase start` / aplicar migraciones y seed:
  `supabase db reset`. `supabase db push` NO sirve para local: empuja a un
  proyecto remoto y exige `supabase link` (falla con "Cannot find project ref").

## Convenciones

- **Nombres entre capas:** Dart en `camelCase`, Postgres/JSON en `snake_case`.
  El mapeo lo generan `freezed` + `json_serializable` con
  `fieldRename: FieldRename.snake`; nunca se escribe a mano.
- **Idioma:** nombres de dominio, tablas, columnas y casos de uso en español
  (`clientes`, `alturaCm`, CU-01…). Identificadores técnicos genéricos
  (nombres de paquetes, clases base de Flutter) en inglés, como es habitual
  en el ecosistema. No traducir lo ya establecido en el ERS.
- **Riverpod:** `@riverpod` (generador), no `StateNotifierProvider` manual.
- **Errores:** `Result<T>` propio (`Success`/`Failure`), nunca excepciones de
  Supabase sin capturar llegando a la interfaz.
- **Acceso a datos:** patrón Repositorio (interfaz en `domain/`,
  implementación Supabase en `data/`); sin capa de "casos de uso" aparte, el
  `Notifier` de `application/` orquesta el repositorio directamente.
- **Tests:** `mocktail` para repositorios; dominio puro sin mocks; widgets
  solo en flujos críticos (login, registro de resultado de sesión).

## Reglas de dominio / trampas conocidas

- **Bajas siempre lógicas**, nunca `DELETE` físico: clientes y ejercicios se
  desactivan (`estado`), no se borran. Ni siquiera el administrador debe
  poder borrarlos físicamente.
- **Fuerza vs. Cardio son mutuamente excluyentes** en `Ejercicio planificado`:
  Fuerza usa Series planificadas/realizadas; Cardio usa
  `minutosPlanificados`/`minutosRealizados`. Nunca ambos a la vez (hay
  trigger que lo valida en base de datos).
- **Lo planificado (entrenador) y lo realizado (cliente) son independientes**:
  no deben forzarse a coincidir; la diferencia es la métrica de rendimiento.
- **RIR en escala 0–10**, tanto planificado como real.
- **Un solo entrenador**: no existe `entrenadorId` ni lógica multi-entrenador.
  No añadirla salvo que se pida explícitamente.
- **El administrador no tiene acceso** a medidas corporales, fotos de
  progreso ni check-in de recuperación de los clientes (por RLS, sin política
  = sin acceso). No crear políticas que se lo den.
- **`service_role` solo dentro de Edge Functions**, nunca en código Flutter.
  Crear o dar de baja un cliente exige pasar por `crear-cliente` /
  `dar-de-baja-cliente`, que validan el rol (`entrenador` o `administrador`)
  antes de usar esa clave.
- **Sesión de entrenamiento NO tiene fecha planificada**: se numera dentro de su
  planning (Día 1, Día 2…), con índice único `(planning_id, orden)`. El
  entrenador planifica *cuántas* sesiones hay, no en qué día caen, para que al
  cliente no le penalice entrenar el jueves lo previsto para el miércoles.
  Lo que sí se guarda es `fecha_realizada`: el día en que el cliente la hizo, que
  rellena un trigger en el primer registro y que la app nunca escribe. Hasta la
  fase 6 la sesión sí tenía fecha planificada; se cambió el 2026-10-04.
- **Sin modo offline y sin multi-entrenador** en esta versión: no diseñar
  pensando en soportarlos ya.

## Forma de trabajar

- Antes de tocar el esquema de base de datos, RLS o una Edge Function,
  plantea el cambio y espera confirmación: son difíciles de revertir en
  producción.
- Cambios de UI o de una sola feature: implementa directamente y explica al
  terminar qué se tocó y por qué.
- Cambios que afectan a varias features o al modelo de dominio: resume el
  plan en 3-4 líneas antes de escribir código.
- Al terminar, indica qué archivos cambiaron y si requieren generar código
  (`build_runner`) o aplicar una migración.

## Límites

- ✅ **Siempre:** seguir la estructura de carpetas y las convenciones ya
  fijadas; usar `Result<T>` para errores; mantener bajas lógicas; correr
  `dart format`/`dart analyze --fatal-infos` antes de dar un cambio por terminado.
- ⚠️ **Pregunta antes:** añadir una dependencia nueva a `pubspec.yaml`;
  crear una migración SQL nueva o modificar una política RLS existente;
  crear una Edge Function nueva; cambiar la estructura de carpetas o el
  patrón de capas; introducir una librería de manejo de errores distinta a
  `Result<T>` (p. ej. `fpdart`/`Either`).
- 🚫 **Nunca:** exponer `SUPABASE_SERVICE_ROLE_KEY` o `RESEND_API_KEY` en
  código Flutter o en `--dart-define`; hacer `DELETE` físico de un cliente o
  ejercicio; saltarse la comprobación de rol en una Edge Function; aplicar
  una migración directamente contra el proyecto de producción sin pasar por
  el pipeline de `main`.

## Verificación

- `dart analyze --fatal-infos` y `flutter test` en verde antes de dar un cambio por
  terminado.
- Si se generó código (`freezed`/`riverpod`), confirmar que
  `build_runner build` no deja errores ni conflictos.
- Si se tocó SQL, probar la migración contra Supabase local (`supabase
  start` + `supabase db reset`) antes de proponerla para `develop`/`main`.
- Si se tocó una Edge Function, probarla localmente (`supabase functions
  serve`) con un token válido y otro inválido, para confirmar que el `403`
  sigue funcionando.


Bitácora de trabajo

Al terminar una tarea con cambios significativos (una funcionalidad, una corrección, un bug encontrado o algo pendiente relevante), añade una entrada a docs/bitacora.md. No reescribas ni borres entradas anteriores: solo añade al final del archivo. Si ya existe una entrada para el día de hoy, añade tu contenido dentro de ella en vez de crear una nueva.

Formato de cada entrada:

markdown
### YYYY-MM-DD

**Hecho:**
- Qué se implementó (feature, CU o RF al que corresponde si aplica).

**Corregido:**
- Qué bug o error se solucionó, y su causa si es relevante.

**Pendiente / notas:**
- Qué queda a medias, qué decisión quedó abierta, qué probar después.

Omite una sección si no aplica ese día (por ejemplo, un día sin bugs no lleva "Corregido"). Usa la fecha real del sistema, no una inventada.
