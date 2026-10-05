#!/usr/bin/env bash
# Instalación del SDK de Flutter para Vercel. Lo llama `vercel.json`
# ("installCommand"), que no trae Flutter de serie.
#
# Va en un script por lo mismo que el de compilar: en `vercel.json` los comandos
# no pueden pasar de 256 caracteres, y así además se puede explicar.
set -euo pipefail

# La misma versión que usan el CI y el entorno de desarrollo. Fija, no "stable":
# el despliegue no debería compilar con una versión distinta a la que pasó los
# tests.
VERSION_FLUTTER=3.47.5
BASE=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux

curl -fsSL "$BASE/flutter_linux_${VERSION_FLUTTER}-stable.tar.xz" | tar -xJ

# El SDK es un repositorio git y lo usa para saber su versión. Si el dueño de la
# carpeta no coincide con el usuario que ejecuta el build, git se niega con
# "detected dubious ownership" y `flutter` no arranca. Esta línea lo evita; es
# inofensiva cuando no hace falta.
git config --global --add safe.directory "$PWD/flutter" || true

flutter/bin/flutter --version
flutter/bin/flutter pub get
