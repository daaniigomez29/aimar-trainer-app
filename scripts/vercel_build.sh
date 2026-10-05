#!/usr/bin/env bash
# Compilación de la web para Vercel. Lo llama `vercel.json` ("buildCommand").
#
# POR QUE UN SCRIPT Y NO EL COMANDO EN `vercel.json`: el schema de Vercel limita
# `buildCommand` a 256 caracteres, y entre las comprobaciones y los cuatro
# `--dart-define` esto pasa de 390. Aquí además se puede comentar y leer.
#
# El SDK de Flutter lo deja en `flutter/` el "installCommand" de `vercel.json`.
set -euo pipefail

# Las variables salen del proyecto en Vercel (Settings → Environment Variables),
# no de `config/prod.json`, que no está en git.
#
# Se comprueban antes de compilar para fallar aquí, con un mensaje que se
# entiende, en vez de publicar una app que arranca sin saber a dónde conectarse.
: "${SUPABASE_URL:?falta la variable de entorno SUPABASE_URL}"
: "${SUPABASE_PUBLISHABLE_KEY:?falta la variable de entorno SUPABASE_PUBLISHABLE_KEY}"

# Sin clave VAPID la app no falla: se queda sin push y la pantalla de
# preferencias lo dice. El correo sigue siendo el respaldo (CU-22).
if [ -z "${VAPID_PUBLIC_KEY:-}" ]; then
  echo "Aviso: sin VAPID_PUBLIC_KEY, esta compilación se queda sin push web."
fi

flutter/bin/flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=APP_ENV="${APP_ENV:-production}" \
  --dart-define=VAPID_PUBLIC_KEY="${VAPID_PUBLIC_KEY:-}"
