#!/usr/bin/env bash
# Uso: ./scripts/restaurar_storage.sh [--si]
#
# Sube los archivos de Storage (las fotos) de la copia de R2 al Storage de
# **Supabase local**, y comprueba que han llegado bien. Es la otra mitad de
# `restaurar_copia.sh`: aquella restaura la base de datos, incluida la tabla
# `storage.objects`, que es solo el **indice** de las fotos (ruta, tamano,
# tipo). Sin los archivos, las fotos salen en los buckets pero en blanco.
#
# Orden para un ensayo completo:
#   1. ./scripts/restaurar_copia.sh <copia> <identidad>   (base de datos)
#   2. ./scripts/restaurar_storage.sh                     (este)
#   3. supabase db reset                                  (volver al seed)
#
# QUE HACE:
#   - `rclone copy --no-check-dest` de `storage/<bucket>` en R2 (descifrando) a
#     cada bucket. `copy` y no `sync`: no borra nada de lo que haya en el
#     destino.
#   - Comprueba con `cryptcheck` que **cada** archivo restaurado es identico al
#     de la copia, y que no falta ninguno. Para eso **descarga** cada archivo
#     del destino, asi que una foto que solo tenga ficha y no archivo da error.
#
# POR QUE `--no-check-dest` (cazado en el primer ensayo, 2026-10-21): el Storage
# de Supabase responde al listado desde la tabla `storage.objects`, no desde los
# archivos. Tras restaurar la base, esa tabla ya trae cada foto con su tamano y
# su fecha, y un `copy` normal las daba por presentes y no subia **ninguna**.
# Las fotos seguian en blanco sin un solo error. Lo mismo pasaria en un
# proyecto nuevo tras restaurar su base: hay que subir sin mirar el destino.
#
# CREDENCIALES: las mismas del Environment `copias` de GitHub. Se leen de
# variables de entorno y, las que falten, se piden por teclado sin mostrarlas.
# No se escriben en ningun archivo ni en el historial.
#   R2_ACCOUNT_ID, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY,
#   RCLONE_CRYPT_PASSWORD, RCLONE_CRYPT_SALT
# Opcional: R2_ENDPOINT, si el bucket no esta en la jurisdiccion UE.
#
# DESTINO: por defecto Supabase local (las claves S3 salen de `supabase
# status`). Para un proyecto de verdad (desastre), definir STORAGE_S3_ENDPOINT,
# STORAGE_S3_REGION, STORAGE_S3_ACCESS_KEY_ID y STORAGE_S3_SECRET_ACCESS_KEY,
# como en el workflow.
#
# Requisitos: rclone (`winget install Rclone.Rclone`) y, para el destino local,
# `supabase start` en marcha.
set -euo pipefail

RCLONE="${RCLONE:-rclone}"
BUCKETS=(fotos-progreso imagenes-ejercicios)
CONFIRMADO="${1:-}"

command -v "$RCLONE" >/dev/null 2>&1 || {
  echo "No encuentro rclone. Instalalo (winget install Rclone.Rclone) o indica" >&2
  echo "donde esta con RCLONE=/ruta/a/rclone." >&2
  exit 1
}

# Pide por teclado lo que no venga en el entorno. `-s` para que los secretos no
# se vean al escribirlos.
pedir() { # pedir <variable> <texto> [secreto]
  local nombre="$1" texto="$2" secreto="${3:-}"
  if [ -z "${!nombre:-}" ]; then
    if [ -n "$secreto" ]; then
      printf '%s (no se muestra): ' "$texto"; read -rs valor; echo
    else
      printf '%s: ' "$texto"; read -r valor
    fi
    [ -n "$valor" ] || { echo "Falta $nombre." >&2; exit 1; }
    printf -v "$nombre" '%s' "$valor"
  fi
}

pedir R2_ACCOUNT_ID "Account ID de Cloudflare"
pedir R2_BUCKET "Nombre del bucket de R2"
pedir R2_ACCESS_KEY_ID "R2 Access Key ID" secreto
pedir R2_SECRET_ACCESS_KEY "R2 Secret Access Key" secreto
pedir RCLONE_CRYPT_PASSWORD "Contrasena de crypt" secreto
pedir RCLONE_CRYPT_SALT "Sal de crypt" secreto
R2_ENDPOINT="${R2_ENDPOINT:-https://$R2_ACCOUNT_ID.eu.r2.cloudflarestorage.com}"

# Destino: un proyecto si se ha dado su endpoint; si no, Supabase local.
if [ -n "${STORAGE_S3_ENDPOINT:-}" ]; then
  DESTINO_LOCAL=""
  DESTINO_NOMBRE="$STORAGE_S3_ENDPOINT"
  pedir STORAGE_S3_REGION "Region del Storage de destino"
  pedir STORAGE_S3_ACCESS_KEY_ID "Access key ID del Storage de destino" secreto
  pedir STORAGE_S3_SECRET_ACCESS_KEY "Secret access key del Storage de destino" secreto
else
  DESTINO_LOCAL="si"
  ESTADO=$(supabase status -o env 2>/dev/null || true)
  valor_local() { printf '%s\n' "$ESTADO" | grep "^$1=" | cut -d'"' -f2; }
  STORAGE_S3_ENDPOINT=$(valor_local STORAGE_S3_URL)
  STORAGE_S3_REGION=$(valor_local S3_PROTOCOL_REGION)
  STORAGE_S3_ACCESS_KEY_ID=$(valor_local S3_PROTOCOL_ACCESS_KEY_ID)
  STORAGE_S3_SECRET_ACCESS_KEY=$(valor_local S3_PROTOCOL_ACCESS_KEY_SECRET)
  [ -n "$STORAGE_S3_ENDPOINT" ] || {
    echo "Supabase local no esta en marcha. Arrancalo con: supabase start" >&2
    exit 1
  }
  DESTINO_NOMBRE="Supabase local ($STORAGE_S3_ENDPOINT)"
fi

if [ "$CONFIRMADO" != "--si" ]; then
  echo "Se van a subir los archivos de la copia (R2: $R2_BUCKET) a: $DESTINO_NOMBRE"
  echo "No se borra nada del destino; lo que ya exista con el mismo nombre se sobrescribe."
  printf "Escribe 'si' para seguir: "
  read -r respuesta
  [ "$respuesta" = "si" ] || { echo "Cancelado."; exit 1; }
fi

# La misma configuracion que el workflow, por variables de entorno.
export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true
export RCLONE_CONFIG_CIFRADO_TYPE=crypt
export RCLONE_CONFIG_CIFRADO_REMOTE="r2:$R2_BUCKET"
export RCLONE_CONFIG_CIFRADO_DIRECTORY_NAME_ENCRYPTION=false
RCLONE_CONFIG_CIFRADO_PASSWORD=$("$RCLONE" obscure "$RCLONE_CRYPT_PASSWORD")
RCLONE_CONFIG_CIFRADO_PASSWORD2=$("$RCLONE" obscure "$RCLONE_CRYPT_SALT")
export RCLONE_CONFIG_CIFRADO_PASSWORD RCLONE_CONFIG_CIFRADO_PASSWORD2
export RCLONE_CONFIG_DESTINO_TYPE=s3
export RCLONE_CONFIG_DESTINO_PROVIDER=Other
export RCLONE_CONFIG_DESTINO_ENDPOINT="$STORAGE_S3_ENDPOINT"
export RCLONE_CONFIG_DESTINO_REGION="$STORAGE_S3_REGION"
export RCLONE_CONFIG_DESTINO_ACCESS_KEY_ID="$STORAGE_S3_ACCESS_KEY_ID"
export RCLONE_CONFIG_DESTINO_SECRET_ACCESS_KEY="$STORAGE_S3_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_DESTINO_FORCE_PATH_STYLE=true

fallos=0

for bucket in "${BUCKETS[@]}"; do
  echo "== $bucket: copiando desde R2 =="
  set +e
  "$RCLONE" copy "cifrado:storage/$bucket" "destino:$bucket" \
    --no-check-dest --retries 1 --low-level-retries 2 \
    --contimeout 15s --timeout 60s --stats-one-line --stats 0 2>&1 \
    | grep -v -E 'Config file .* not found' | sed 's/^/   /'
  estado=${PIPESTATUS[0]}
  set -e
  if [ "$estado" -ne 0 ]; then
    echo "   FALLO: no se han podido subir todos los archivos." >&2
    fallos=$((fallos + 1))
    continue
  fi
  echo "   subidos: $("$RCLONE" lsf -R --files-only "cifrado:storage/$bucket" 2>/dev/null | wc -l | tr -d ' ') archivos"

  echo "== $bucket: comprobando que cada archivo es identico a la copia =="
  # Sin `--one-way`: avisa tanto de un archivo distinto como de uno que falte
  # en cualquiera de los dos lados.
  #
  # La salida se ve en el momento y sin reintentos largos: si algo falla, el
  # error tiene que aparecer enseguida, no tras minutos de esperas crecientes
  # entre reintentos sin decir nada (paso en el primer ensayo, 2026-10-21).
  set +e
  "$RCLONE" cryptcheck "destino:$bucket" "cifrado:storage/$bucket" \
    --retries 1 --low-level-retries 2 --contimeout 15s --timeout 60s -v 2>&1 \
    | grep -v -E 'Config file .* not found' | sed 's/^/   /'
  estado=${PIPESTATUS[0]}
  set -e
  if [ "$estado" -ne 0 ]; then
    echo "   FALLO: el destino no coincide con la copia." >&2
    fallos=$((fallos + 1))
  fi
done

echo
if [ "$fallos" -eq 0 ]; then
  echo "Todo correcto: los archivos restaurados son identicos a la copia y no falta ninguno."
else
  echo "Hay $fallos comprobacion(es) con fallos: revisa la salida de arriba." >&2
  exit 1
fi
