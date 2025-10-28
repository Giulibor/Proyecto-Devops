#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-traveltrack}"
RELEASE="${RELEASE:-traveltrack}"
kubectl delete -f kyverno/disallow-latest.yaml --ignore-not-found
kubectl delete -f kyverno/require-resources.yaml --ignore-not-found
kubectl delete -f kyverno/disallow-root.yaml --ignore-not-found
helm uninstall "${RELEASE}" --namespace "${NS}" || true
kubectl delete namespace "${NS}" --ignore-not-found
helm uninstall falco --namespace falco || true
kubectl delete namespace falco --ignore-not-found
