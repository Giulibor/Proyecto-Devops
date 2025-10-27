#!/usr/bin/env bash
set -euo pipefail

# Permite correrlo standalone o desde 01_up.sh
K8S_DIR="${K8S_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/k8s}"

echo "==> 01c) Chequeando CRDs de Prometheus Operator"
if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1 && \
   kubectl get crd prometheusrules.monitoring.coreos.com   >/dev/null 2>&1; then
  echo "==> CRDs OK. Aplicando overlay monitoring"
  kubectl apply -k "$K8S_DIR/monitoring"
else
  echo "❌ No existen los CRDs de monitoring. Instalá el Operator (kube-prometheus-stack) antes."
  exit 1
fi
