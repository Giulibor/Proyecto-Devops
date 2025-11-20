#!/usr/bin/env bash
set -e

eval "$(minikube docker-env)"

APP_NAMESPACE="${APP_NAMESPACE:-lab4}"

echo "[+] Bajar release Helm"
helm uninstall lab4 -n "$APP_NAMESPACE" || true

echo "[+] Borrar namespace ${APP_NAMESPACE}"
kubectl delete ns "$APP_NAMESPACE" --wait=false || true

echo "[+] Borrando contenedor de jenkins"
docker rm -f jenkins-lab4 || true
eval "$(minikube docker-env -u)"
docker rm -f jenkins-lab4 || true

#echo "[+] Borrar imagen de minikube"
#eval "$(minikube docker-env)"
#docker rmi snake-app:1.0.1 || true
