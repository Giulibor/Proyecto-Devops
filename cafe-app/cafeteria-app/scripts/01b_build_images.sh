#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_TAG="cafeteria-app:latest"

echo "==> [01] Construyendo ${APP_TAG}"
docker build -t "$APP_TAG" "$APP_DIR"

echo "==> [02] Listo. Imágenes construidas:"
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E "$APP_TAG" || true