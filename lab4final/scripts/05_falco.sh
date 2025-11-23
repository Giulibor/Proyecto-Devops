#!/usr/bin/env bash
set -e

APP_NAMESPACE="${APP_NAMESPACE:-lab4}"
eval "$(minikube docker-env)"

echo "[+] Instalando Falco (detección de amenazas)"
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm upgrade --install falco falcosecurity/falco \
    --namespace falco \
    --create-namespace
