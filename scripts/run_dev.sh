#!/usr/bin/env bash
# Uso: ./scripts/run_dev.sh
# Requiere config/dev.json con SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY y APP_ENV
# (formato en el README). Para Supabase local, los valores salen de
# `supabase status`. config/dev.json no se sube a Git.

# Puerto fijo para que coincida con `site_url` de supabase/config.toml: los
# enlaces de invitacion y de recuperacion solo redirigen a una URL permitida.
flutter run   --web-hostname=127.0.0.1   --web-port=3000   --dart-define-from-file=config/dev.json
