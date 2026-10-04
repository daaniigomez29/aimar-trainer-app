#!/usr/bin/env bash
# Uso: ./scripts/servir_funciones_host.sh   (y en otra terminal)
#      BASE_FUNCIONES=http://127.0.0.1:54331 ./scripts/probar_local.sh
#
# Sirve las tres Edge Functions con el Deno del host, SIN Docker. Es un apano
# para cuando `supabase functions serve` no puede crear su contenedor (ver
# `docs/estado-actual.md`, trampa del edge runtime con Docker 29). Para el uso
# normal, `supabase functions serve --no-verify-jwt` sigue siendo lo suyo:
# aquello corre el runtime de verdad, esto solo el codigo de las funciones.
set -euo pipefail

cd "$(dirname "$0")/.."

set -a
. supabase/functions/.env
set +a

estado() { supabase status -o json 2>/dev/null | python -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }

# Desde el host no resuelven los nombres de contenedor de la red de Docker.
export CORREO_DEV_URL=http://127.0.0.1:54324
export SUPABASE_URL=$(estado API_URL)
export SUPABASE_ANON_KEY=$(estado ANON_KEY)
export SUPABASE_SERVICE_ROLE_KEY=$(estado SERVICE_ROLE_KEY)
export SUPABASE_PUBLISHABLE_KEYS=$(supabase status -o json | python -c "import sys,json;print(json.dumps([json.load(sys.stdin)['PUBLISHABLE_KEY']]))")
export RAIZ_FUNCIONES="file://$(pwd -W 2>/dev/null || pwd)/supabase/functions"
export PUERTO_FUNCIONES=${PUERTO_FUNCIONES:-54331}

exec deno run --allow-all --config supabase/functions/deno.json \
  scripts/servir_funciones_host.ts
