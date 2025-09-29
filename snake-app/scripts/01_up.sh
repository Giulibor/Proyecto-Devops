#!/usr/bin/env bash
set -euo pipefail

# Config
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# SNAKE_DIR="$APP_DIR/snake-app"
SNAKE_DIR="$APP_DIR"
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

echo "==> 4) Construyendo imágenes (delegado a 00_build_images.sh)"
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_build_images.sh"

echo "==> 5) Aplicando manifests"
kubectl apply -f "$K8S_DIR/deployment-blue.yaml"
kubectl apply -f "$K8S_DIR/deployment-green.yaml"
kubectl apply -f "$K8S_DIR/service.yaml"

echo "==> 6) Esperando rollouts"
kubectl rollout status deploy/snake-app-blue
kubectl rollout status deploy/snake-app-green

echo "==> 7) Pods actuales"
kubectl get pods -l app=snake-app -o wide

echo "==> 8) URL estable del Service (NodePort)"
echo "==> Abriendo Service con minikube (dejá esta terminal abierta para visualizar la app)"
minikube service snake-app