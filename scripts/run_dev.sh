#!/usr/bin/env bash
# Uso: ./scripts/run_dev.sh
# Requiere config/dev.json con SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY y APP_ENV
# (formato en el README). Para Supabase local, los valores salen de
# `supabase status`. config/dev.json no se sube a Git.
#
# El puerto es fijo y debe coincidir con `site_url` de supabase/config.toml: GoTrue
# solo redirige los enlaces de invitacion y de recuperacion a una URL permitida.
#
# Se usa 54330 porque esta FUERA del rango dinamico de Windows (1024-15000), del
# que Hyper-V y Docker reservan bloques. El 3000 cayo dentro de uno de esos bloques
# y dejo de poder abrirse con "errno 10013", aunque nadie lo estuviera usando.

flutter run \
  --web-hostname=127.0.0.1 \
  --web-port=54330 \
  --dart-define-from-file=config/dev.json
