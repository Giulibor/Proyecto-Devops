#!/usr/bin/env bash
set -euo pipefail

# Uso: ./02_rollout.sh blue|green
COLOR="${1:-green}"
if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
  echo "Uso: $0 blue|green" >&2
  exit 1
fi

echo "==> Cambiando Service a color=$COLOR"
kubectl patch svc snake-app -p "{\"spec\":{\"selector\":{\"app\":\"snake-app\",\"color\":\"$COLOR\"}}}"

echo "==> Servicio snake-app"
kubectl get svc snake-app -o wide 

echo "==> Abriendo Service con minikube (dejá esta terminal abierta para visualizar la app)"
minikube service snake-app