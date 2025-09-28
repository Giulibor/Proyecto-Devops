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

echo "==> Endpoints del Service"
kubectl get endpoints snake-app -o wide

echo "==> Comprobando por curl (cierra conexión por request para evitar keep-alive)"
MINI_IP="$(minikube ip)"
NODEPORT="$(kubectl get svc snake-app -o jsonpath='{.spec.ports[0].nodePort}')"
for i in {1..8}; do
  printf "req %02d -> " "$i"
  curl -s -H 'Connection: close' "http://$MINI_IP:$NODEPORT/" | head -n1
done

echo "==> URL del Service"
echo "http://$MINI_IP:$NODEPORT"