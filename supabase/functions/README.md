# Edge Functions

Funciones con privilegios elevados. `SUPABASE_SERVICE_ROLE_KEY` solo se usa
aquí, nunca en el código Flutter.

| Función               | Caso de uso               | Estado                                        |
| --------------------- | ------------------------- | --------------------------------------------- |
| `crear-cliente`       | CU-17 Dar de alta cliente | Esqueleto: valida rol y datos, devuelve `501` |
| `dar-de-baja-cliente` | CU-18 Dar de baja cliente | Esqueleto: valida rol y datos, devuelve `501` |

La validación de rol (`_shared/autorizacion.ts`) ya es la definitiva: ambas
exigen un JWT válido de `entrenador` o `administrador` y cortan con `401`/`403`
**antes** de instanciar el cliente `service_role`.

## Probar en local

```bash
supabase start
supabase functions serve --no-verify-jwt
```

Con `--no-verify-jwt` la comprobación del JWT recae en la propia función, que es
lo que interesa verificar:

```bash
# 401 — sin cabecera Authorization
curl -i -X POST http://127.0.0.1:54321/functions/v1/crear-cliente \
  -H 'Content-Type: application/json' -d '{}'

# 401 — token inventado
curl -i -X POST http://127.0.0.1:54321/functions/v1/crear-cliente \
  -H 'Authorization: Bearer token-invalido' \
  -H 'Content-Type: application/json' -d '{}'

# 403 — JWT válido de un usuario con rol 'cliente'
# 501 — JWT válido de 'entrenador' o 'administrador' (aún sin implementar)
```

## Variables de entorno

Inyectadas por Supabase: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` y dos
claves públicas **de valor distinto**, ambas válidas para identificar el
proyecto:

| Variable                    | Contenido                                                       |
| --------------------------- | --------------------------------------------------------------- |
| `SUPABASE_PUBLISHABLE_KEYS` | JSON `{"default": "sb_publishable_..."}`, formato actual        |
| `SUPABASE_ANON_KEY`         | clave heredada; su valor es un JWT (`eyJ...`), no la publicable |

`clavePublicaDelProyecto()` prefiere la primera y solo cae a la segunda si no
está disponible.

Los dos nombres los fija Supabase, no el proyecto: **no existe**
`SUPABASE_PUBLISHABLE_KEY` en singular dentro de una Edge Function, así que un
renombrado global dejaría la clave en `undefined`.

### Las que declaras tú

Solo los secretos propios del proyecto. En local, en `supabase/functions/.env`
(ignorado por git; plantilla en `.env.example`), que `supabase functions serve`
carga solo. **Importante:** el valor real de `RESEND_API_KEY` no se pone nunca
en `.env.example`, que sí se versiona. En `.env.example` van marcadores; el
valor real va en `.env`, que está ignorado. `RESEND_FROM_EMAIL` y `APP_BASE_URL`
no son secretos y pueden llevar su valor real en la plantilla.

En la nube hay dos formas equivalentes, y los secretos son **por proyecto** (dev
y prod se configuran por separado):

```bash
# Desde el fichero local, de una vez
supabase secrets set --env-file supabase/functions/.env --project-ref <ref>

# O uno a uno
supabase secrets set RESEND_API_KEY=re_... --project-ref <ref>

# Comprobar qué hay puesto (muestra nombres y hashes, no los valores)
supabase secrets list --project-ref <ref>
```

`--project-ref` no hace falta si el proyecto está vinculado con
`supabase link --project-ref <ref>`.

La otra vía es la interfaz web: _Project Settings > Edge Functions > Secrets_.
Hace exactamente lo mismo; el CLI es preferible porque queda reproducible.

Los secretos se guardan en el proyecto, no en el despliegue: se configuran una
vez y las funciones que se despliegan después ya los ven. El pipeline de GitHub
Actions no necesita reenviarlos en cada despliegue.

`supabase secrets` **no afecta al entorno local**: en local siempre se lee
`supabase/functions/.env` (o `supabase/functions/<funcion>/.env` para una
función concreta). Esa ruta por defecto la confirma
`supabase functions serve --help`: `--env-file` "overrides
supabase/functions/.env and per-Function .env files".

| Variable            | Para qué                                               |
| ------------------- | ------------------------------------------------------ |
| `RESEND_API_KEY`    | Envío de correo (invitaciones, recordatorios)          |
| `RESEND_FROM_EMAIL` | Remitente verificado en Resend                         |
| `APP_BASE_URL`      | URL pública de la PWA, para los enlaces de los correos |

Nunca se declaran a mano `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_PUBLISHABLE_KEYS` ni `SUPABASE_SERVICE_ROLE_KEY`: las inyecta la
plataforma.
