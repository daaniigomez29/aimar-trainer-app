#!/usr/bin/env bash
# Uso: ./scripts/restaurar_copia.sh <bd-AAAA-MM-DD.tar.gz.age> <identidad-age.txt> [--si]
#
# Restaura en **Supabase local** una copia de la base de datos sacada por
# `.github/workflows/copias.yml`. Sirve para dos cosas:
#
#   1. El ensayo periodico: una copia que nunca se ha restaurado no es una
#      copia, es una esperanza. Igual que el SQL, que no vale hasta que se
#      ejecuta contra local.
#   2. Mirar como estaban los datos un dia concreto, sin tocar produccion.
#
# Para restaurar en un proyecto **nuevo** de Supabase (desastre de verdad), ver
# `docs/copias-de-seguridad.md`: ahi se cargan tambien los roles y el esquema.
#
# QUE HACE:
#   - Descifra la copia con la clave privada de age y la desempaqueta.
#   - `supabase db reset --no-seed`: la base local queda con el esquema de las
#     migraciones y sin datos. **Borra lo que hubiera en local.**
#   - Carga los datos de la copia en una sola transaccion: o entran todos, o no
#     entra nada y la base se queda vacia (y se puede volver a intentar).
#   - Ensena cuantas filas hay en las tablas principales.
#
# No restaura los archivos de Storage (las fotos): esos se traen con rclone,
# ver la guia.
#
# Requisitos: `supabase start` en marcha, Docker, y `age` en el PATH (en
# Windows: `winget install FiloSottile.age`). Si age no esta en el PATH, se le
# puede indicar con la variable AGE.
set -euo pipefail

# Git Bash convierte las rutas tipo `/tmp/...` en rutas de Windows, y entonces
# `docker cp` y `docker exec` no encuentran los archivos dentro del contenedor.
export MSYS_NO_PATHCONV=1

# Y por lo mismo, a los programas nativos de Windows (age instalado con winget,
# docker.exe) hay que pasarles las rutas ya convertidas: con la conversion
# apagada recibirian `/c/Users/...` y no encontrarian nada. En Linux y macOS no
# existe cygpath y las rutas valen tal cual.
ruta_nativa() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

AGE="${AGE:-age}"

if [ $# -lt 2 ]; then
  echo "Uso: $0 <bd-AAAA-MM-DD.tar.gz.age> <identidad-age.txt> [--si]" >&2
  exit 2
fi

COPIA="$1"
IDENTIDAD="$2"
CONFIRMADO="${3:-}"

[ -f "$COPIA" ] || { echo "No existe la copia: $COPIA" >&2; exit 1; }
[ -f "$IDENTIDAD" ] || { echo "No existe la identidad: $IDENTIDAD" >&2; exit 1; }
command -v "$AGE" >/dev/null 2>&1 || {
  echo "No encuentro age. Instalalo (winget install FiloSottile.age) o indica" >&2
  echo "donde esta con AGE=/ruta/a/age." >&2
  exit 1
}

# El contenedor de la base local. Se usa su `psql` en vez de pedir uno
# instalado: si Supabase local esta en marcha, este siempre esta.
CONTENEDOR=$(docker ps --format '{{.Names}}' | grep '^supabase_db_' | head -1 || true)
[ -n "$CONTENEDOR" ] || {
  echo "Supabase local no esta en marcha. Arrancalo con: supabase start" >&2
  exit 1
}

if [ "$CONFIRMADO" != "--si" ]; then
  echo "Esto BORRA la base de datos local ($CONTENEDOR) y la sustituye por la copia."
  printf "Escribe 'si' para seguir: "
  read -r respuesta
  [ "$respuesta" = "si" ] || { echo "Cancelado."; exit 1; }
fi

TRABAJO=$(mktemp -d)
# El volcado descifrado son datos de salud en claro: no se dejan en disco.
trap 'rm -rf "$TRABAJO"' EXIT

echo "== Descifrando =="
"$AGE" -d -i "$(ruta_nativa "$IDENTIDAD")" \
  -o "$(ruta_nativa "$TRABAJO/copia.tar.gz")" "$(ruta_nativa "$COPIA")"
tar -xzf "$TRABAJO/copia.tar.gz" -C "$TRABAJO"
for archivo in roles.sql schema.sql data.sql; do
  [ -f "$TRABAJO/$archivo" ] || {
    echo "La copia no trae $archivo: no es una copia de copias.yml." >&2
    exit 1
  }
done
ls -l "$TRABAJO"/*.sql

echo "== Dejando la base local vacia (migraciones, sin seed) =="
supabase db reset --no-seed

echo "== Cargando los datos =="
# Por que asi:
#   - `session_replication_role = replica` apaga los triggers mientras se
#     carga: los datos ya pasaron por ellos cuando se escribieron, y volver a
#     dispararlos recalcularia cosas o, como el de "lo pasado no se toca",
#     rechazaria semanas que ya terminaron.
#   - `delete from storage.buckets`: el reset vuelve a crear los dos buckets
#     desde config.toml, y la copia tambien los trae. Sin esto, la carga choca
#     con la clave primaria en la primera fila.
#   - `--single-transaction` y `ON_ERROR_STOP`: o entra todo, o nada.
docker cp "$(ruta_nativa "$TRABAJO/data.sql")" "$CONTENEDOR:/tmp/restaurar_data.sql"
docker exec "$CONTENEDOR" psql -U postgres -q \
  --single-transaction -v ON_ERROR_STOP=1 \
  -c "SET session_replication_role = replica" \
  -c "delete from storage.buckets" \
  -f /tmp/restaurar_data.sql >/dev/null
docker exec "$CONTENEDOR" rm -f /tmp/restaurar_data.sql

echo "== Filas restauradas =="
docker exec "$CONTENEDOR" psql -U postgres -At -F ' ' -c "
  select 'auth.users', count(*) from auth.users
  union all select 'clientes', count(*) from clientes
  union all select 'ejercicios', count(*) from ejercicios
  union all select 'plannings_semanales', count(*) from plannings_semanales
  union all select 'ejercicios_planificados', count(*) from ejercicios_planificados
  union all select 'series_realizadas', count(*) from series_realizadas
  union all select 'registros_medidas', count(*) from registros_medidas
  union all select 'packs', count(*) from packs
  union all select 'storage.objects', count(*) from storage.objects;" \
  | while read -r tabla filas; do printf '  %-26s %s\n' "$tabla" "$filas"; done

echo
echo "Hecho. Para entrar con las cuentas de la copia hacen falta sus contrasenas"
echo "reales: el seed de local no se ha cargado."
