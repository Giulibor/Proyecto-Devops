#!/usr/bin/env bash
set -e

# ----- Vars -----
APP_NAMESPACE="${APP_NAMESPACE:-lab4}"
eval "$(minikube docker-env)"

echo "[+] Limpiando posible ingress-nginx viejo del addon de minikube"
minikube addons disable ingress || true

kubectl delete ns ingress-nginx --ignore-not-found
kubectl delete clusterrole ingress-nginx --ignore-not-found
kubectl delete clusterrolebinding ingress-nginx --ignore-not-found
kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found

echo "[+] Instalando ingress-nginx via Helm (requerido para Admission Webhook)"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# ----- Namespaces base -----
echo "[+] Crear namespace ${APP_NAMESPACE}"
kubectl get ns "$APP_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$APP_NAMESPACE"

echo "[+] Deploy Kyverno"
sh ./04_kyverno.sh

echo "[+] Deploy Falco"
sh ./05_falco.sh

echo "[+] Build de imagen Angular (snake-app:1.0.1)"
docker build -t snake-app:1.0.1 ../front/snakeapp

echo "[+] Deploy/upgrade con Helm en namespace ${APP_NAMESPACE}"
helm upgrade --install lab4 ../helm/lab4-demo \
  -f ../helm/lab4-demo/values.yaml \
  -f ../helm/lab4-demo/values-dev.yaml \
  -n "$APP_NAMESPACE"

echo "[i] Verifico que los pods inicien correctamente y que el servicio sea 
accesible (sleep 5)"
sleep 5
kubectl get pods -n lab4
kubectl get svc -n lab4
kubectl get ingress -n lab4
kubectl describe deployment lab4-lab4-demo -n lab4 | grep -i image

echo "[+] Deploy Jenkins"
sh ./03_jenkins.sh

echo "[i] Generar reporte kyverno"
kubectl get policyreport -A -o yaml > ../reports/kyverno-validation.log

echo "[i] Generar reporte Falco"
FALCO_POD=$(kubectl get pods -n falco -l app.kubernetes.io/name=falco -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n falco "$FALCO_POD" -c falco > ../reports/falco-event.log || true
