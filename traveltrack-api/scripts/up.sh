#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-traveltrack}"
RELEASE="${RELEASE:-traveltrack}"
IMAGE="${IMAGE:-traveltrack-api}"
TAG="${TAG:-0.1.0}"
APP_VERSION="${APP_VERSION:-0.1.0}"
mkdir -p ../reports
npm ci
npm run build
npm run lint || true
npm run semgrep || true
npm run audit || true
docker build -t "${IMAGE}:${TAG}" -f dockerfile .
trivy image --severity HIGH,CRITICAL --no-progress --format table -o ../reports/trivy-report.txt "${IMAGE}:${TAG}" || true
if command -v kind >/dev/null 2>&1 && kind get clusters >/dev/null 2>&1; then kind load docker-image "${IMAGE}:${TAG}" || true; fi
helm upgrade --install "${RELEASE}" ./chart --namespace "${NS}" --create-namespace --set image.repository="${IMAGE}" --set image.tag="${TAG}" --set appVersion="${APP_VERSION}"
kubectl apply -f ../kyverno/disallow-latest.yaml
kubectl apply -f ../kyverno/require-resources.yaml
kubectl apply -f ../kyverno/disallow-root.yaml
kube-linter lint ../chart/ > ../reports/kubelinter.txt || true
cat > ../tmp/kyverno-bad.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-bad
spec:
  containers:
    - name: c
      image: nginx:latest
YAML
kubectl apply -f ../test-manifests/kyverno-bad.yaml > ../reports/kyverno-violation.txt 2>&1 || true
kubectl delete -f ../test-manifests/kyverno-bad.yaml --ignore-not-found
helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true
helm upgrade --install falco falcosecurity/falco --namespace falco --create-namespace
sleep 5
kubectl -n "${NS}" rollout status deploy/traveltrack-deploy --timeout=120s || true
kubectl -n "${NS}" exec deploy/traveltrack-deploy -- sh -c "cat /etc/shadow" >/dev/null 2>&1 || true
kubectl -n falco logs -l app.kubernetes.io/name=falco --tail=1000 > ../reports/falco-event.log || true