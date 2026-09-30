#!/usr/bin/env bash
# Uso: ./scripts/run_dev.sh
# Requiere config/dev.json con SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY y APP_ENV
# (formato en el README). Para Supabase local, los valores salen de
# `supabase status`. config/dev.json no se sube a Git.

flutter run --dart-define-from-file=config/dev.json
