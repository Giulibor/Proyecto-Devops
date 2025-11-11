#!/usr/bin/env bash
set -euo pipefail

# Carga .env si existe (variables por CLI tienen prioridad)
# Ejemplo .env:
#   GH_USER=cardo88
#   GH_TOKEN=ghp_xxx
#   VERSION=0.1.2
#   NAMESPACE=traveltrack
if [ -f ".env" ]; then
  # shellcheck disable=SC2046
  export $(grep -E '^[A-Z0-9_]+=' .env | xargs -0)
fi

# Defaults
: "${VERSION:=0.1.2}"
: "${NAMESPACE:=traveltrack}"

# Requeridos para publicar
: "${GH_USER:=}"
: "${GH_TOKEN:=}"

echo "[INFO] Iniciando smoke end-to-end para TravelTrack API"
echo "[INFO] VERSION=$VERSION NAMESPACE=$NAMESPACE GH_USER=${GH_USER:-<vacío>}"

# 1) Build en host para publicar en GHCR
make use-host-docker
make build-host VERSION="$VERSION"

# 2) Publicar a GHCR y sincronizar values.yaml (repository/tag)
if [ -n "${GH_USER}" ] && [ -n "${GH_TOKEN}" ]; then
  export GH_USER GH_TOKEN
  make ghcr-publish VERSION="$VERSION"
else
  echo "[WARN] GH_USER/GH_TOKEN no seteados; se salta publicación a GHCR"
fi

# 3) Build dentro de Minikube para que el cluster vea la imagen
make build-in-minikube VERSION="$VERSION"

# 4) Render a YAML y aplicar al cluster
make render NAMESPACE="$NAMESPACE"
make apply  NAMESPACE="$NAMESPACE"

# 5) Smoke test básico de endpoints
make smoke NAMESPACE="$NAMESPACE"

echo "[OK] Smoke finalizado correctamente"