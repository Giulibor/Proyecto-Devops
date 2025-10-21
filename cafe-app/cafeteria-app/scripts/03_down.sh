#!/usr/bin/env bash
set -euo pipefail

APP_NS="cafeteria"
MON_NS="monitoring"
STOP_MINIKUBE="${STOP_MINIKUBE:-true}"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$APP_DIR/k8s"

echo "==> 1) Eliminando namespaces de la app y monitoring"
kubectl delete ns "$APP_NS" --ignore-not-found=true || true
kubectl delete ns "$MON_NS" --ignore-not-found=true || true

echo "==> 2) Eliminando overlays si aún existen"
kubectl delete -k "$K8S_DIR/monitoring" --ignore-not-found=true || true

echo "==> 3) Revirtiendo docker-env"
eval "$(minikube docker-env -u)"

if [ "$STOP_MINIKUBE" = "true" ]; then
  echo "==> 4) Deteniendo minikube"
  minikube stop
fi

echo
echo "✅ Limpieza completa."
echo "ℹ️  Minikube detenido: $STOP_MINIKUBE"
echo "ℹ️  Tu shell vuelve a apuntar al Docker local."