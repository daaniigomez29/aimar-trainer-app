#!/usr/bin/env bash
# Uso: ./scripts/build_prod.sh
# Requiere config/prod.json con los valores del proyecto de produccion
# (Settings > API) y "APP_ENV": "production". config/prod.json no se sube a Git.
# Este build es el que se despliega en Vercel (normalmente via el pipeline de
# GitHub Actions; esto es para probarlo en local antes).
#
# Pendiente: el proyecto de produccion aun no existe, asi que config/prod.json
# esta vacio y este script fallara hasta que se rellene.

flutter build web --dart-define-from-file=config/prod.json
