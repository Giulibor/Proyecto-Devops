#!/usr/bin/env bash
set -euo pipefail

MON_NS="monitoring"
RELEASE_NAME="${RELEASE_NAME:-kube-prom-stack}"

echo "==> Namespace de monitoring: ${MON_NS}"
kubectl get ns "${MON_NS}" >/dev/null

# -------- Grafana --------
echo "==> Buscando Pod de Grafana…"
GRAFANA_POD="$(kubectl get pod -n "${MON_NS}" \
  -l 'app.kubernetes.io/name=grafana' \
  -o jsonpath='{.items[0].metadata.name}')"

if [[ -z "${GRAFANA_POD}" ]]; then
  echo "❌ No encontré un Pod de Grafana en el ns ${MON_NS}. ¿Está instalado kube-prometheus-stack?"
  exit 1
fi

# Puerto por defecto del container de Grafana
GRAFANA_PORT="$(kubectl get pod -n "${MON_NS}" "${GRAFANA_POD}" \
  -o jsonpath='{.spec.containers[0].ports[0].containerPort}')"

# Obtener admin password del Secret del chart (si existe)
echo "==> Intentando leer la password admin de Grafana del Secret…"
if kubectl get secret -n "${MON_NS}" "${RELEASE_NAME}-grafana" >/dev/null 2>&1; then
  GRAFANA_PASS="$(kubectl get secret -n "${MON_NS}" "${RELEASE_NAME}-grafana" \
    -o jsonpath='{.data.admin-password}' | base64 -d)"
  echo "   Usuario: admin"
  echo "   Password: ${GRAFANA_PASS}"
else
  echo "   No encontré el Secret ${RELEASE_NAME}-grafana. Si usaste otro release, exportá RELEASE_NAME."
fi

echo "==> Haciendo port-forward de Grafana en http://localhost:3000"
# Corre en background y limpia al salir
kubectl -n "${MON_NS}" port-forward "pod/${GRAFANA_POD}" 3000:"${GRAFANA_PORT}" >/dev/null 2>&1 &
GRAFANA_FWD_PID=$!

# -------- Prometheus --------
echo "==> Buscando Pod de Prometheus…"
PROM_POD="$(kubectl get pod -n "${MON_NS}" \
  -l 'app.kubernetes.io/name=prometheus' \
  -o jsonpath='{.items[0].metadata.name}')"

if [[ -z "${PROM_POD}" ]]; then
  # fallback: algunos charts usan otro label
  PROM_POD="$(kubectl get pod -n "${MON_NS}" \
    -l 'prometheus=kube-prometheus-stack' \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
fi

if [[ -n "${PROM_POD}" ]]; then
  PROM_PORT="$(kubectl get pod -n "${MON_NS}" "${PROM_POD}" \
    -o jsonpath='{.spec.containers[0].ports[0].containerPort}')"
  echo "==> Haciendo port-forward de Prometheus en http://localhost:9090"
  kubectl -n "${MON_NS}" port-forward "pod/${PROM_POD}" 9090:"${PROM_PORT}" >/dev/null 2>&1 &
  PROM_FWD_PID=$!
else
  echo "⚠️  No encontré un Pod de Prometheus. Continuo solo con Grafana."
fi

echo
echo "Listo:"
echo "  • Grafana    → http://localhost:3000  (user: admin)"
echo "  • Prometheus → http://localhost:9090  (si apareció arriba)"
echo
echo "Tips:"
echo "  En Prometheus probá esta query: sum(increase(orders_total[5m])) by (product)"
echo "  En Grafana, importá el datasource Prometheus (si el chart no lo creó) y graficá 'orders_total'."
echo
echo "Presioná Ctrl+C para terminar los port-forwards."
trap 'echo; echo "Cerrando port-forwards…"; kill ${GRAFANA_FWD_PID:-0} ${PROM_FWD_PID:-0} 2>/dev/null || true' INT TERM
wait
