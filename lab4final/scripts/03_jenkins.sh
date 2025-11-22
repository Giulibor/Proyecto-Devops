#!/usr/bin/env bash
set -e

eval "$(minikube docker-env -u)"

docker rm -f jenkins-lab4 2>/dev/null || true

docker network inspect lab4-net >/dev/null 2>&1 || docker network create lab4-net
docker run -d --name jenkins-lab4 \
  --restart unless-stopped \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home_lab4:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$HOME/.kube:/var/jenkins_home/.kube:ro" \
  -v "$PWD/../jenkins/init_admin.groovy":/var/jenkins_home/init.groovy.d/init_admin.groovy:ro \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  jenkins/jenkins:2.537-jdk21

echo "[i] Instalando plugins de jenkins"
docker exec jenkins-lab4 bash -c \
  "jenkins-plugin-cli --plugins \
  workflow-aggregator \
  git \
  git-client \
  credentials \
  credentials-binding \
  scm-api \
  plain-credentials \
  junit"

docker exec jenkins-lab4 bash -c \
  "pip install semgrep ; npm install -g snyk"

docker restart jenkins-lab4
echo "[i] Listo, jenkins iniciado"
echo "http://localhost:8081"
echo "user: admin"
echo "pass: admin123"