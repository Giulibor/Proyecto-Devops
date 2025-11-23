#!/usr/bin/env bash
set -e

echo "== Validando imagen con Trivy =="
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD/../reports:/reports \
  aquasec/trivy:latest \
  image snake-app:1.0.1 \
  --severity CRITICAL,HIGH,MEDIUM \
  --ignore-unfixed \
  --format table \
  --output /reports/trivy-image-vulns.txt

echo "== Validando imagen con dive =="
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest \
  snake-app:1.0.1
