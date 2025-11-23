#!/usr/bin/env bash
set -e

APP_NAMESPACE="${APP_NAMESPACE:-lab4}"
eval "$(minikube docker-env)"

echo "[+] Instalar/actualizar Kyverno via Helm"
helm repo add kyverno https://kyverno.github.io/kyverno >/dev/null 2>&1 || true
helm repo update kyverno
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

echo "[+] Aplicar políticas de Kyverno para el namespace ${APP_NAMESPACE}"
kubectl apply -f ../kyverno/disallow-latest.yaml
kubectl apply -f ../kyverno/require-resources.yaml
kubectl apply -f ../kyverno/disallow-root.yaml
kubectl apply -f ../kyverno/require-probes.yaml