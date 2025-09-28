#!/usr/bin/env bash
set -euo pipefail

# Config
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAKE_DIR="$APP_DIR/snake-app"
BLUE_TAG="snake-app:v1-blue"
GREEN_TAG="snake-app:v2-green"
K8S_DIR="$SNAKE_DIR/k8s"

echo "==> 1) Iniciando minikube (driver=docker)"
minikube start --driver=docker

echo "==> 2) Apuntando Docker local al daemon de minikube"
eval "$(minikube docker-env)"

echo "==> 3) Limpiando recursos previos SOLO de snake-app (no borro todo el cluster)"
kubectl delete deploy -l app=snake-app --ignore-not-found
kubectl delete svc    -l app=snake-app --ignore-not-found
kubectl delete pod    -l app=snake-app --ignore-not-found

echo "==> 4) Construyendo imágenes"
cd "$SNAKE_DIR"

# Recomendación: verificar manualmente el H1 antes de cada build si querés “ver” el cambio en pantalla.
#   v1 (blue):  <h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v1 (blue)</span></h1>
#   v2 (green): <h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v2 (green)</span></h1>

echo "    - Build BLUE -> $BLUE_TAG"
docker build -t "$BLUE_TAG" .

echo "==> 5) Ahora cambiá el H1 para v2 (green), guardá el archivo y presioná ENTER para seguir…"
read -r

echo "    - Build GREEN -> $GREEN_TAG"
docker build -t "$GREEN_TAG" .

echo "==> 6) Aplicando manifests"
kubectl apply -f "$K8S_DIR/deployment-blue.yaml"
kubectl apply -f "$K8S_DIR/deployment-green.yaml"
kubectl apply -f "$K8S_DIR/service.yaml"

echo "==> 7) Esperando rollouts"
kubectl rollout status deploy/snake-app-blue
kubectl rollout status deploy/snake-app-green

echo "==> 8) Pods actuales"
kubectl get pods -l app=snake-app -o wide

echo "==> 9) URL estable del Service (NodePort)"
URL="$(minikube service snake-app --url)"
echo "    $URL"
if command -v open >/dev/null 2>&1; then open "$URL"; fi

echo "Listo. Refrescá el navegador con Cmd/Ctrl+Shift+R cuando hagas rollout."