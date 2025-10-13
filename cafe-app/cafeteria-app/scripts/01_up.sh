#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  echo "No corras este script como root con --driver=docker. Usá tu usuario normal."
  exit 1
fi

command -v minikube >/dev/null || { echo "Falta minikube"; exit 1; }
command -v kubectl  >/dev/null || { echo "Falta kubectl";  exit 1; }

# --- Config ---
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$APP_DIR/k8s"
APP_NAME="cafeteria-app"
APP_NS="cafeteria"
MON_NS="monitoring"
HELM_RELEASE="${HELM_RELEASE:-kube-prom-stack}"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEM="${MINIKUBE_MEM:-2200mb}"

have_crds() {
  kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1 && \
  kubectl get crd prometheusrules.monitoring.coreos.com  >/dev/null 2>&1
}

install_helm_if_missing() {
  if command -v helm >/dev/null 2>&1; then
    echo "➡️  Helm ya está instalado: $(helm version --short)"
    return
  fi
  echo "⬇️  Instalando Helm (sin sudo)…"
  local DIR="${HELM_INSTALL_DIR:-$HOME/.local/bin}"
  mkdir -p "$DIR"
  case ":$PATH:" in *":$DIR:"*) ;; *) export PATH="$DIR:$PATH" ;; esac
  export HELM_INSTALL_DIR="$DIR" USE_SUDO=0

  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  hash -r || true

  if ! command -v helm >/dev/null 2>&1; then
    echo "❌ Helm no quedó en PATH (PATH=$PATH)"; exit 1
  fi
  grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "✅ Helm instalado: $(helm version --short)"
}

install_kube_prom_stack_if_missing() {
  if helm -n "$MON_NS" status "$HELM_RELEASE" >/dev/null 2>&1; then
    echo "➡️  kube-prometheus-stack ya instalado (release=$HELM_RELEASE, ns=$MON_NS)"; return
  fi
  echo "⬇️  Instalando kube-prometheus-stack…"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
  helm repo update >/dev/null
  helm upgrade --install "$HELM_RELEASE" prometheus-community/kube-prometheus-stack \
    -n "$MON_NS" --create-namespace
  echo "⏳ Esperando CRDs del Prometheus Operator…"
  until have_crds; do sleep 3; done
  echo "✅ CRDs disponibles."
}

echo "==> 1) Iniciando minikube (driver=docker, ${MINIKUBE_CPUS} CPU, ${MINIKUBE_MEM} RAM)"
minikube start --driver=docker --cpus="$MINIKUBE_CPUS" --memory="$MINIKUBE_MEM"

echo "==> 2) Apuntando Docker local al daemon de minikube"
eval "$(minikube -p minikube docker-env)"

echo "==> 3) Asegurando contexto de kubectl"
minikube -p minikube update-context

echo "==> 4) Limpiando recursos previos (solo app)"
kubectl delete ns "$APP_NS" --ignore-not-found=true || true

echo "==> 5) Construyendo imagen de la app"
"$APP_DIR/scripts/01b_build_images.sh"   # debe construir cafeteria-app:latest

echo "==> 6) Aplicando kustomization base (ns, postgres, app)"
kubectl apply -k "$K8S_DIR/base"

echo "==> 7) Esperando rollout de la app"
kubectl -n "$APP_NS" rollout status "deploy/$APP_NAME"

echo "==> 8) Verificando Helm y kube-prometheus-stack"
install_helm_if_missing
install_kube_prom_stack_if_missing

echo "==> 9) Aplicando overlay k8s/monitoring"
export K8S_DIR MON_NS HELM_RELEASE
"$APP_DIR/scripts/01c_monitoring.sh"

echo "==> 10) Pods actuales"
kubectl -n "$APP_NS" get pods -o wide

echo "==> 11) Abriendo Service de la app con minikube"
minikube service -n "$APP_NS" "$APP_NAME"

echo
echo "✅ Todo listo."
echo "ℹ️ Para abrir Grafana/Prometheus con port-forward: $APP_DIR/scripts/02_ports.sh"