# Arquitectura e infraestructura

## Restricciones de alcance

- Un único entrenador: no hay multi-entrenador ni `entrenadorId`.
- Sin modo offline en esta versión.
- Sin registro libre de clientes: todas las cuentas de cliente las crea el
  entrenador (o el administrador) desde la aplicación.
- Distribución solo web (PWA) en esta fase; Android e iOS quedan para una
  fase posterior. El código específico de plataforma se aísla tras
  interfaces propias para facilitar ese salto sin refactorizar dominio ni
  datos.
- La administración de cuentas de entrenador y tareas técnicas de la
  plataforma se realiza directamente desde el panel de Supabase por el
  administrador técnico, fuera del alcance funcional de la app (no es un
  caso de uso).
- El administrador no tiene acceso a medidas corporales, fotos de progreso
  ni check-in de recuperación de los clientes (minimización de datos).

## Capas

| Capa | Tecnología | Responsabilidad |
| --- | --- | --- |
| Cliente | Flutter Web (PWA), Riverpod | Interfaz y validación de reglas de dominio para feedback inmediato |
| Autenticación | Supabase Auth | Login, recuperación de contraseña, sesiones |
| Datos | Supabase Postgres (región UE) | Persistencia, constraints, triggers, RLS |
| Ficheros | Supabase Storage (bucket privado) | Fotos de progreso, URLs firmadas |
| Lógica de servidor | Supabase Edge Functions | Operaciones con privilegios elevados |
| Tareas programadas | pg_cron | Disparo de recordatorios |
| Correo | Resend (dominio propio verificado) | Invitaciones, recuperación, recordatorios |
| Hosting web | Vercel | Servir la PWA |
| CI/CD | GitHub Actions | Build, tests, migraciones, despliegue |

## Roles y seguridad

Tres roles en tabla `perfiles` enlazada a Supabase Auth: `administrador`,
`entrenador`, `cliente` — cuentas independientes entre sí (administrador y
entrenador nunca son la misma cuenta).

| Rol | Puede |
| --- | --- |
| Cliente | Ver su planning, registrar series/minutos, medidas y check-in, consultar su progreso |
| Entrenador | Gestionar biblioteca, plannings y fichas de cliente; consultar registros de sus clientes |
| Administrador | Gestionar cuentas y configuración técnica; sin acceso a medidas, fotos ni check-in |

- **RLS activado en todas las tablas.** Cada regla de dominio se traduce en
  una política (ver `sql-schema.md`).
- **Doble validación**: Flutter valida para feedback inmediato; Postgres
  garantiza las reglas con constraints/triggers, sin depender del cliente.
- **`service_role` solo dentro de Edge Functions**, nunca en código Flutter.
- Datos de salud en región UE; bucket de fotos privado con URLs firmadas de
  corta duración; consentimiento explícito del cliente en el alta.

## Alta y baja de clientes

Tanto el **entrenador** como el **administrador** pueden dar de alta y de
baja clientes. La comprobación de rol vive en la propia Edge Function, no
solo en RLS: crear un usuario en Auth exige `service_role`, así que sin esa
verificación cualquiera con la URL del endpoint podría crear cuentas.

```typescript
// supabase/functions/crear-cliente/index.ts
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("No autorizado", { status: 401 });

  const supabaseCliente = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: authError } = await supabaseCliente.auth.getUser();
  if (authError || !user) return new Response("No autorizado", { status: 401 });

  const { data: perfil } = await supabaseCliente
    .from("perfiles").select("rol").eq("id", user.id).single();

  const rolesPermitidos = ["entrenador", "administrador"];
  if (!perfil || !rolesPermitidos.includes(perfil.rol)) {
    return new Response("Prohibido", { status: 403 });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // 1. Crear usuario en Auth e invitar por correo (Resend)
  // 2. Insertar perfil (rol = 'cliente')
  // 3. Insertar ficha en clientes con los datos recibidos
});
```

```typescript
// supabase/functions/dar-de-baja-cliente/index.ts
// Misma validación de cabecera y rol (entrenador o administrador). Con supabaseAdmin:
// 1. update clientes set estado = 'baja', fecha_baja = now() where id = clienteId
// 2. supabaseAdmin.auth.admin.updateUserById(clienteId, { ban_duration: "876000h" })
```

El `403` corta antes de tocar `service_role`: ni un `POST` directo con
`curl`/Postman puede crear o dar de baja un cliente sin un JWT válido de
`entrenador` o `administrador`.

### Contrato de las Edge Functions

**POST /functions/v1/crear-cliente**

Petición:
```json
{
  "nombre": "string",
  "correo": "string",
  "fechaNacimiento": "YYYY-MM-DD | null",
  "alturaCm": "number | null",
  "pesoInicialKg": "number | null",
  "objetivos": "string | null",
  "diaControlPreferido": "lunes|martes|...|domingo"
}
```
Respuesta `201`: `{ "clienteId": "uuid", "estado": "invitado" }`
Errores: `401` sin token · `403` rol no autorizado · `409` correo ya
registrado (activo) · `400` datos inválidos

Variables de entorno: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY` (inyectadas por Supabase), más
`RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `APP_BASE_URL`.

**POST /functions/v1/dar-de-baja-cliente**

Petición: `{ "clienteId": "uuid" }`
Respuesta `200`: `{ "clienteId": "uuid", "estado": "baja" }`
Errores: `401` · `403` · `404` cliente no encontrado · `409` ya estaba de baja

Mismas variables de entorno que `crear-cliente`.

## Notificaciones y correo

- Proveedor único: Resend, con dominio propio verificado (puede ser un
  subdominio del dominio web existente de Aimar).
- Un job de pg_cron invoca diariamente una Edge Function que identifica:
  clientes con sesión programada al día siguiente, y clientes cuyo
  `diaControlPreferido` es el día actual.
- Canales combinados: notificación push web + correo. El push llega en
  Android/Chrome y en iOS 16.4+ solo con la PWA instalada; el correo es el
  respaldo universal.
- Cálculo de fechas en zona horaria Europe/Madrid.

## Entornos y despliegue

| Rama | Supabase | Vercel |
| --- | --- | --- |
| main | Proyecto de producción | Despliegue de producción |
| develop | Proyecto de desarrollo | Preview con URL propia |
| feature/* | Supabase local (Docker) | Preview automática por PR |

- El esquema vive como migraciones SQL en el repositorio
  (`supabase/migrations`); GitHub Actions las aplica al integrar en
  `develop` (proyecto dev) y en `main` (proyecto prod).
- La configuración por entorno se inyecta en Flutter Web vía
  `--dart-define` en tiempo de compilación.
- El pipeline compila con `flutter build web` y despliega el resultado
  estático en Vercel.

## Variables de entorno y secretos

| Dónde | Nombre | Contenido |
| --- | --- | --- |
| Flutter (`--dart-define`) | `SUPABASE_URL` | URL pública del proyecto (dev/prod) |
| Flutter (`--dart-define`) | `SUPABASE_ANON_KEY` | Clave pública |
| Flutter (`--dart-define`) | `APP_ENV` | `development` \| `production` |
| Supabase Edge Functions | `SUPABASE_SERVICE_ROLE_KEY` | Inyectada automáticamente, nunca a mano |
| Supabase Edge Functions | `RESEND_API_KEY` | Clave de API de Resend |
| Supabase Edge Functions | `RESEND_FROM_EMAIL` | Remitente verificado |
| Supabase Edge Functions | `APP_BASE_URL` | URL pública de la PWA |
| GitHub Actions | `SUPABASE_ACCESS_TOKEN` | Migraciones vía CLI |
| GitHub Actions | `SUPABASE_PROJECT_ID_DEV` / `_PROD` | Referencia de proyecto por entorno |
| GitHub Actions | `SUPABASE_URL_DEV` / `_PROD`, `SUPABASE_ANON_KEY_DEV` / `_PROD` | Para el build por entorno |
| GitHub Actions | `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` | Despliegue a Vercel |

**Nunca** en código Flutter ni en `--dart-define`: `SUPABASE_SERVICE_ROLE_KEY`,
`RESEND_API_KEY`.

## Riesgos de infraestructura gratuita y mitigaciones

| Riesgo | Mitigación |
| --- | --- |
| Supabase pausa proyectos inactivos | Ping periódico desde GitHub Actions |
| Sin backups automáticos en el plan gratuito | Volcado periódico (`pg_dump`) como artefacto de CI |
| Límites de envío de Resend | Volumen actual muy por debajo; revisar si crece el nº de clientes |
| Resend exige dominio propio verificado | Usar un subdominio o el dominio raíz ya existente |
| Condiciones de uso comercial de planes gratuitos | Revisar periódicamente términos vigentes de cada proveedor |

## Requisitos no funcionales relevantes para infraestructura

- **RNF-01:** prever un procedimiento de anonimización/eliminación de datos
  de un cliente a petición (derecho de supresión, RGPD). La baja lógica no
  lo cubre por sí sola; pendiente de definir como caso de uso futuro.
- **RNF-02:** los datos de salud deben alojarse en infraestructura ubicada
  en la Unión Europea.
- **RNF-03:** el código específico de plataforma debe aislarse tras
  interfaces propias, para permitir añadir Android sin refactorizar la
  lógica de dominio.
