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
  -v "$HOME/.minikube:$HOME/.minikube:ro" \
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

echo "[i] Instalando semgrep en el contenedor (como root)"
docker exec -u 0 jenkins-lab4 bash -c '
  set -e
  apt-get update
  apt-get install -y python3 python3-pip
  pip3 install --break-system-packages semgrep
'

echo "[i] Instalando Node, NPM y snyk (como root)"
docker exec -u 0 jenkins-lab4 bash -c \
  "apt-get install -y curl && \
   curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
   apt-get install -y nodejs && \
   npm install -g snyk"


echo "[i] Instalando Docker CLI, kubectl y Helm (como root)"
docker exec -u 0 jenkins-lab4 bash -c '
  set -e
  # Docker CLI
  apt-get install -y docker.io

  # kubectl
  curl -L https://dl.k8s.io/release/v1.34.2/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl

  # Helm
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
'

echo "[i] Reiniciando el contenedor"
docker restart jenkins-lab4

echo "[i] Listo, Jenkins iniciado"
echo "http://localhost:8081"
echo "user: admin"
echo "pass: admin123"
