#!/usr/bin/env bash
set -euo pipefail

echo "==> Eliminando recursos de snake-app"
kubectl delete deploy -l app=snake-app --ignore-not-found
kubectl delete svc    -l app=snake-app --ignore-not-found
kubectl delete pod    -l app=snake-app --ignore-not-found

echo "==> Revirtiendo variables de entorno de Docker (minikube docker-env -u)"
# Solo afecta tu shell actual
eval "$(minikube docker-env -u)"

echo "==> Deteniendo minikube"
minikube stop

# Si querés dejar TODO como antes de crear el cluster, descomentar:
# echo "==> Borrando cluster minikube"
# minikube delete --all --purge

echo "Listo. Tu shell vuelve a apuntar a tu Docker local y minikube quedó detenido."