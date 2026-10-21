# Copias de seguridad

Cómo se hacen, dónde están, qué hace falta para restaurarlas y cómo se ensaya.
Montado el 2026-10-19: hasta entonces la app estaba en producción sin ninguna
copia (el plan gratuito de Supabase no las hace).

## Qué se copia y dónde

Cada noche a las 02:30 UTC, `.github/workflows/copias.yml`:

| Qué | Cómo | Dónde (bucket de R2) | Cuánto se guarda |
| --- | --- | --- | --- |
| Base de datos entera (`auth.users` incluido) | `supabase db dump`: roles, esquema y datos, empaquetados y cifrados con **age** | `bd/diarias/bd-AAAA-MM-DD.tar.gz.age` | 30 días |
| La del día 1 de cada mes | La misma copia | `bd/mensuales/` | 12 meses |
| Archivos de `fotos-progreso` e `imagenes-ejercicios` | `rclone sync` incremental a un remoto `crypt` | `storage/<bucket>/` | Siempre la versión vigente |
| Archivos borrados o reemplazados | `--backup-dir` del mismo `sync` | `storage-historico/<fecha>/<bucket>/` | 90 días |

Todo va cifrado **antes de salir del runner**: en R2 solo hay archivos
ilegibles. La base, con la clave pública de age. Los archivos, con la
contraseña de `crypt`, que cifra el contenido y los nombres de archivo. Los
nombres de las carpetas (`fotos-progreso/<cliente_id>/<registro_id>/`) quedan
legibles a propósito, para que las reglas de caducidad de R2 reconozcan
`storage-historico/` por su prefijo.

**Lo que no está en la copia, y hay que tener aparte:**

- Los secretos de **Vault** (`url_enviar_recordatorios`, el secreto del cron) y
  los de las **Edge Functions** (`RESEND_API_KEY`, `VAPID_*`, `SECRETO_CRON`).
  Vault cifra con una clave del propio proyecto, así que en otro no servirían.
- La **configuración de Auth** del panel: SMTP de Resend, Site URL, URLs de
  redirección y plantillas de correo.
- Las variables de **Vercel** y los secretos de **GitHub**.

Todo eso va al gestor de contraseñas, junto a las claves de abajo.

## Las claves que solo tienes tú

Sin ellas, las copias no se pueden abrir. **Si se pierden, las copias no
sirven.** Guárdalas en el gestor de contraseñas **y** en una copia fuera de
línea (impresa o en un USB guardado aparte).

1. **Clave privada de age** (`AGE-SECRET-KEY-1...`): descifra la base de datos.
   ```bash
   winget install FiloSottile.age
   age-keygen -o aimar-copias.age.txt
   ```
   El archivo contiene la privada. La pública (`age1...`) la imprime el comando
   y también está dentro del archivo, en la línea `# public key:`. Solo la
   pública va a GitHub.
2. **Contraseña y sal de rclone `crypt`**: descifran las fotos. Dos cadenas
   largas y aleatorias, distintas:
   ```bash
   openssl rand -base64 32
   ```
   Se guardan **tal cual**. El workflow las ofusca con `rclone obscure` al
   arrancar; no hay que ofuscarlas a mano.

## Puesta en marcha

### 1. Cloudflare R2

1. Crear el bucket (por ejemplo, `aimar-copias`) con **Location → Specify
   jurisdiction → European Union**. La jurisdicción solo se elige al crearlo.
   Su endpoint es `https://<ACCOUNT_ID>.eu.r2.cloudflarestorage.com`, que es el
   que usa el workflow.
2. **Manage R2 API Tokens → Create API token**: permiso **Object Read & Write**,
   limitado a ese bucket. Da un *Access Key ID* y un *Secret Access Key*.
3. **Reglas de ciclo de vida** del bucket (Settings → Object lifecycle rules),
   todas de borrado:

   | Prefijo | Borrar a los |
   | --- | --- |
   | `bd/diarias/` | 30 días |
   | `bd/mensuales/` | 365 días |
   | `storage-historico/` | 90 días |

   `storage/` **sin regla**: es la copia vigente de los archivos.

### 2. Supabase

- **Cadena de conexión del session pooler**: panel → Connect → *Session
  pooler*. Tiene la forma
  `postgresql://postgres.<ref>:<contraseña>@aws-0-<región>.pooler.supabase.com:5432/postgres`.
  La conexión directa **no sirve**: solo funciona por IPv6 y los runners de
  GitHub son IPv4. Si la contraseña lleva símbolos, tienen que ir
  *percent-encoded*.
- **Claves S3 de Storage**: panel → Storage → Settings → *S3 Connection*. Ahí
  están el endpoint (`https://<ref>.storage.supabase.co/storage/v1/s3`), la
  región y el botón para crear una *access key*. **Esa clave salta RLS**: da
  acceso a todo Storage. Solo va al Environment de las copias.

### 3. GitHub: Environment `copias`

Settings → Environments → **New environment** → `copias`, con estos secretos:

| Secreto | Valor |
| --- | --- |
| `SUPABASE_DB_URL` | La cadena del session pooler |
| `AGE_RECIPIENT` | La clave **pública** de age (`age1...`) |
| `R2_ACCOUNT_ID` | El *Account ID* de Cloudflare |
| `R2_BUCKET` | El nombre del bucket |
| `R2_ACCESS_KEY_ID` | Del token de R2 |
| `R2_SECRET_ACCESS_KEY` | Del token de R2 |
| `STORAGE_S3_ENDPOINT` | `https://<ref>.storage.supabase.co/storage/v1/s3` |
| `STORAGE_S3_REGION` | La región que muestra el panel (p. ej. `eu-west-3`) |
| `STORAGE_S3_ACCESS_KEY_ID` | De la *access key* de Storage |
| `STORAGE_S3_SECRET_ACCESS_KEY` | De la *access key* de Storage |
| `RCLONE_CRYPT_PASSWORD` | La contraseña de `crypt`, tal cual |
| `RCLONE_CRYPT_SALT` | La sal de `crypt`, tal cual |

Es un Environment propio, no el de `main`: este job no despliega nada y no
tiene por qué ver el token de despliegue. Si falta un secreto, el job **falla**
en vez de saltarse, al contrario que el despliegue: una copia que se salta en
silencio es justo lo que no puede pasar.

### 4. Primera copia

Actions → **Copias de seguridad** → *Run workflow*. Después, comprobar en R2 que
existen `bd/diarias/bd-<hoy>.tar.gz.age` y `storage/`, y **hacer el primer
ensayo de restauración** (abajo). Hasta que no se haya restaurado una vez, no
se sabe si funciona.

## Verificación y diagnóstico

**Cada noche se comprueba que las fotos copiadas son idénticas a las de
Supabase**, no solo que están. Tras el `sync`, `rclone cryptcheck` toma la
huella (md5) de cada original, la cifra con los mismos datos de cifrado que su
copia y la compara con la huella que R2 guarda de la copia. No descarga nada.
Si un solo archivo no coincide, el job sale en rojo y llega el correo. La copia
de la base de datos no lo necesita: `rclone copyto` ya compara su md5 con el de
R2 al subirla.

**Errores de rclone**: rclone reintenta hasta 3 veces y solo da el paso por
bueno si al final todo está copiado. Errores en el primer intento con el job en
verde no son una copia a medias, pero conviene saber de dónde salen. Para
verlo: Actions → *Copias de seguridad* → *Run workflow* con la casilla
**depurar** marcada. Hace una sola pasada sin reintentos y muestra cada llamada
HTTP con su código de respuesta. La autorización sale tapada y las líneas con
las claves se filtran antes de llegar al log. Sí salen los nombres de archivo
del lado de Supabase, así que el log solo debe verlo quien tenga acceso al
repositorio.

**Pendiente (2026-10-21)**: en la primera ejecución real, cada foto dio
`501 NotImplemented` en el primer intento y se copió bien en el segundo. Contra
el Storage local no pasa, así que viene de R2. Falta una pasada con **depurar**
para ver qué llamada lo devuelve.

## Restaurar

### Ensayo en local (o para mirar un día concreto)

1. Descargar la copia desde el panel de R2 (`bd/diarias/` o `bd/mensuales/`).
2. Con `supabase start` en marcha:
   ```bash
   ./scripts/restaurar_copia.sh bd-AAAA-MM-DD.tar.gz.age aimar-copias.age.txt
   ```
   Pide confirmación (con `--si` no la pide), **borra la base local**, aplica
   las migraciones sin seed y carga los datos en una sola transacción. Al
   acabar enseña cuántas filas hay en las tablas principales. Para entrar
   hacen falta las contraseñas reales de las cuentas, porque el seed no se
   carga.

Comprobado el 2026-10-19 con un volcado real de la base local: mismos
recuentos antes y después, el login devuelve 200 con la contraseña buena y 400
con la mala, y no queda ningún archivo descifrado en disco.

**Cada cuánto**: el primero al montarlo, y después cada 3 meses o tras un
cambio grande de esquema. Un ensayo que falla es un aviso barato; una copia que
no restaura el día que hace falta, no.

### Los archivos de Storage

Con rclone (`winget install Rclone.Rclone`) y la misma configuración que el
workflow, por variables de entorno:

```bash
export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID=... RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=...
export RCLONE_CONFIG_R2_ENDPOINT=https://<ACCOUNT_ID>.eu.r2.cloudflarestorage.com
export RCLONE_CONFIG_CIFRADO_TYPE=crypt RCLONE_CONFIG_CIFRADO_REMOTE=r2:<bucket>
export RCLONE_CONFIG_CIFRADO_DIRECTORY_NAME_ENCRYPTION=false
export RCLONE_CONFIG_CIFRADO_PASSWORD=$(rclone obscure '<contraseña crypt>')
export RCLONE_CONFIG_CIFRADO_PASSWORD2=$(rclone obscure '<sal crypt>')

# Ver qué hay, ya descifrado:
rclone ls cifrado:storage/fotos-progreso
# Bajar los archivos vigentes a una carpeta:
rclone copy cifrado:storage/fotos-progreso ./fotos-restauradas
# Recuperar algo borrado o reemplazado (mirar antes la fecha):
rclone ls cifrado:storage-historico
rclone copy cifrado:storage-historico/AAAA-MM-DD/fotos-progreso ./recuperadas
```

Para subirlas a un proyecto, añadir un remoto `supabase` con las variables
`RCLONE_CONFIG_SUPABASE_*` del workflow y hacer `rclone copy` de
`cifrado:storage/<bucket>` a `supabase:<bucket>`.

Comprobado el 2026-10-19 contra el Storage local, con una carpeta en lugar de
R2: los nombres salen cifrados, ningún contenido en claro, una foto borrada se
recupera byte a byte del histórico, y las noches sin cambios no vuelven a subir
nada. **Lo que no se ha podido probar es la conexión con R2 de verdad**: se
verá en la primera ejecución.

### Desastre: proyecto nuevo de Supabase

**No ensayado.** Es el mismo camino que el ensayo en local, apuntando a otro
proyecto:

1. Crear el proyecto en la región UE y anotar su ref.
2. Aplicar las migraciones: `supabase link --project-ref <ref>` y
   `supabase db push`. Así el proyecto tiene el esquema **y** el historial de
   migraciones, y el CI puede seguir desplegando sobre él.
3. Cargar los datos, igual que hace el script con la base local:
   ```bash
   psql "<cadena del session pooler del proyecto nuevo>" \
     --single-transaction -v ON_ERROR_STOP=1 \
     -c "SET session_replication_role = replica" \
     -c "delete from storage.buckets" \
     -f data.sql
   ```
   `data.sql` sale de descifrar la copia:
   `age -d -i aimar-copias.age.txt bd-...tar.gz.age | tar -xz`.
4. Si faltan los buckets, crearlos con `supabase seed buckets` (salen de
   `config.toml`). Después, subir los archivos con rclone (arriba).
5. Volver a poner lo que no está en la copia: secretos de Vault y de las Edge
   Functions, configuración de Auth, desplegar las funciones, y cambiar
   `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` en Vercel y los secretos del CI.

`roles.sql` y `schema.sql` van en la copia como referencia, y por si algún día
hubiera que restaurar sin el repositorio. En ese caso el orden es el de la guía
oficial de Supabase: roles, esquema y datos, con `psql`.

## Coste y límites

- **R2**: 10 GB gratis. Hoy la base cifrada ocupa decenas de KB y las fotos son
  lo que crecerá. Con la caducidad, lo ocupado se estabiliza en lugar de crecer
  sin límite.
- **GitHub Actions**: unos pocos minutos por noche.
- Si algún día se pasa a **Supabase Pro**, sus copias diarias de 7 días se
  quedan dentro de Supabase. Esta copia externa conviene mantenerla igualmente.
- Cloudflare es una empresa estadounidense, como Supabase. Con el cifrado y la
  clave solo en tu poder, lo que guarda son archivos ilegibles. Hay que
  añadirlo como encargado del tratamiento en el registro del RGPD.
