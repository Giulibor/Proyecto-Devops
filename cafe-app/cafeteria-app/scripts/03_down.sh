#!/usr/bin/env bash
set -euo pipefail
APP_NS="cafeteria"
STOP_MINIKUBE="${STOP_MINIKUBE:-true}"

echo "==> Eliminando recursos"
kubectl delete ns "$APP_NS" --ignore-not-found=true || true
kubectl delete -k "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/k8s/monitoring" --ignore-not-found=true || true

echo "==> Revirtiendo docker-env"
eval "$(minikube docker-env -u)"

if [ "$STOP_MINIKUBE" = "true" ]; then
  echo "==> Deteniendo minikube"
  minikube stop
fi

echo "Listo."
