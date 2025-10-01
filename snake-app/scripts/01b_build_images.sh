#!/usr/bin/env bash
set -euo pipefail

# Script: 00_build_images.sh
# Objetivo: Cambiar el H1 visible en app.component.html y construir las imágenes
#           BLUE (v1) y GREEN (v2) de snake-app. Al finalizar, restaura el archivo.
#
# Uso:
#   sh snake-app/scripts/00_build_images.sh
#
# Variables (opcionales):
#   BLUE_TAG  (default: snake-app:v1-blue)
#   GREEN_TAG (default: snake-app:v2-green)

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # -> snake-app
SNAKE_DIR="$APP_DIR"
BLUE_TAG="${BLUE_TAG:-snake-app:v1-blue}"
GREEN_TAG="${GREEN_TAG:-snake-app:v2-green}"

APP_HTML="$SNAKE_DIR/src/app/app.component.html"
BLUE_LINE='<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v1 (blue)</span></h1>'
GREEN_LINE='<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v2 (green)</span></h1>'

echo "==> [01] Validando archivo HTML objetivo"
if [[ ! -f "$APP_HTML" ]]; then
  echo "ERROR: No se encontró $APP_HTML" >&2
  exit 1
fi

echo "==> [02] Creando backup temporal de app.component.html"
cp "$APP_HTML" "$APP_HTML.bak"

replace_h1() {
  local target_line="$1"
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS (BSD sed)
    sed -i '' -E "s|<h1>.*</h1>|$target_line|" "$APP_HTML" || true
  else
    # Linux (GNU sed)
    sed -i -E "s|<h1>.*</h1>|$target_line|" "$APP_HTML" || true
  fi

  # Si no se reemplazó (no matcheó), forzar con awk la primera ocurrencia
  if ! grep -qE "<h1>.*</h1>" "$APP_HTML"; then
    awk -v repl="$target_line" '
      BEGIN{done=0}
      { if(!done && $0 ~ /<h1>.*<\/h1>/){ print repl; done=1; next }
        { print $0 }
      }' "$APP_HTML" > "$APP_HTML.tmp" && mv "$APP_HTML.tmp" "$APP_HTML"
  fi
}

echo "==> [03] Seteando H1 a v1 (blue) y construyendo ${BLUE_TAG}"
replace_h1 "$BLUE_LINE"
grep "<h1>" "$APP_HTML" || true
docker build -t "$BLUE_TAG" "$SNAKE_DIR"

echo "==> [04] Seteando H1 a v2 (green) y construyendo ${GREEN_TAG}"
replace_h1 "$GREEN_LINE"
grep "<h1>" "$APP_HTML" || true
docker build -t "$GREEN_TAG" "$SNAKE_DIR"

# echo "==> [05] Restaurando app.component.html original"
# mv "$APP_HTML.bak" "$APP_HTML"

echo "==> [06] Listo. Imágenes construidas:"
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'snake-app:(v1-blue|v2-green)' || true