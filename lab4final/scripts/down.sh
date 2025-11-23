#!/usr/bin/env bash
set -e

APP_NAMESPACE="${APP_NAMESPACE:-lab4}"

echo "[+] Apuntando Docker al daemon de Minikube"
eval "$(minikube docker-env)"

echo "[+] Bajar release Helm de la app (lab4)"
helm uninstall lab4 -n "$APP_NAMESPACE" || true

echo "[+] Borrar namespace de la app: ${APP_NAMESPACE}"
kubectl delete ns "$APP_NAMESPACE" --wait=false || true

echo "[+] Bajar ingress-nginx instalado via Helm"
helm uninstall ingress-nginx -n ingress-nginx || true
kubectl delete ns ingress-nginx --wait=false || true

echo "[+] Bajar Kyverno"
helm uninstall kyverno -n kyverno || true
kubectl delete ns kyverno --wait=false || true

echo "[+] Bajar Falco"
helm uninstall falco -n falco || true
kubectl delete ns falco --wait=false || true

echo "[+] Borrar imágenes de la app del daemon de Minikube"
docker rmi snake-app:1.0.1 snake-app:1.0.3 snake-app:latest 2>/dev/null || true

echo "[+] Volver a usar el Docker del host"
eval "$(minikube docker-env -u)"

echo "[+] Borrando contenedor de Jenkins en el host"
docker rm -f jenkins-lab4 2>/dev/null || true

echo "[+] Borrando volumen de Jenkins (si existe)"
#docker volume rm jenkins_home_lab4 2>/dev/null || true

echo "[+] Borrando red lab4-net (si existe)"
#docker network rm lab4-net 2>/dev/null || true

echo "[+] Limpieza completa del laboratorio finalizada"