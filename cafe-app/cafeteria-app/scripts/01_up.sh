#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  echo "No corras este script como root con --driver=docker. Usá tu usuario normal."
  exit 1
fi

command -v minikube >/dev/null || { echo "Falta minikube"; exit 1; }
command -v kubectl  >/dev/null || { echo "Falta kubectl";  exit 1; }

# Config
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$APP_DIR/k8s"
APP_NAME="cafeteria-app"
APP_NS="cafeteria"
MON_NS="monitoring"
HELM_RELEASE="${HELM_RELEASE:-kube-prom-stack}"

have_crds() {
  kubectl get crd servicemonitors.monitoring.coreos.com    >/dev/null 2>&1 && \
  kubectl get crd prometheusrules.monitoring.coreos.com    >/dev/null 2>&1
}

install_helm_if_missing() {
  if command -v helm >/dev/null 2>&1; then
    echo "➡️  Helm ya está instalado: $(helm version --short)"
    return
  fi
  echo "⬇️  Instalando Helm…"
  # Instalador oficial
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "✅ Helm instalado: $(helm version --short)"
}

install_kube_prom_stack_if_missing() {
  if helm -n "$MON_NS" status "$HELM_RELEASE" >/dev/null 2>&1; then
    echo "➡️  kube-prometheus-stack ya instalado (release=$HELM_RELEASE, ns=$MON_NS)"
    return
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

echo "==> 1) Iniciando minikube (driver=docker)"
minikube start --driver=docker

echo "==> 2) Apuntando Docker local al daemon de minikube"
eval "$(minikube -p minikube docker-env)"

echo "==> 3) Limpiando recursos previos"
kubectl delete ns "$APP_NS" --ignore-not-found=true || true #Como uso el mismo namespace para todo, es más facil borrar el NS que borrar pods, deploy y svc por separado ;)

echo "==> 4) Construyendo imágenes"
"$APP_DIR/scripts/01b_build_images.sh"

echo "==> 5) Aplicando kustomization"
kubectl apply -k "$K8S_DIR/base" #Uso kustomization para no tener que hacer apply a cada manifest por separado

echo "==> 6) Esperando rollouts"
kubectl -n "$APP_NS" rollout status "deploy/$APP_NAME"

echo "==> 7) Verificando Helm"
install_helm_if_missing
install_kube_prom_stack_if_missing

echo "==> 7) Aplicando k8s/monitoring"
# exporto variables para que las vea el script hijo (por si lo corrés aparte también)
export K8S_DIR MON_NS HELM_RELEASE
"$APP_DIR/scripts/01c_monitoring.sh"

echo "==> 8) Pods actuales"
kubectl -n "$APP_NS" get pods -l app=$APP_NAME -o wide

echo "==> 8) Exponiendo svc con minikube (y lo abre en el navegador)"
minikube service -n "$APP_NS" "$APP_NAME"

echo
echo "✅ Todo listo."
echo "ℹ️ Para abrir Grafana/Prometheus con port-forward: $APP_DIR/scripts/02_ports.sh"