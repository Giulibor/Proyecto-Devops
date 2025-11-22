#!/usr/bin/env bash
set -e

eval "$(minikube docker-env -u)"

docker rm -f jenkins-lab4 2>/dev/null || true

docker network inspect lab4-net >/dev/null 2>&1 || docker network create lab4-net

# Copiás el kubeconfig original
cp "$HOME/.kube/config" /tmp/kubeconfig-jenkins

# Sacás el puerto real que usa minikube en el host (ej: 64737)
PORT=$(grep 'server: https://127.0.0.1:' "$HOME/.kube/config" | sed 's#.*127.0.0.1:\([0-9]\+\).*#\1#')
echo "PUERTO MINIKUBE = $PORT"

# Apuntás al hostname 'minikube' con ese puerto
sed -i "s#https://127.0.0.1:[0-9]\+#https://minikube:${PORT}#" /tmp/kubeconfig-jenkins

# Cambiás todas las rutas /home/coco/.minikube → /var/jenkins_home/.minikube
#sed -i 's#/home/coco/.minikube#/var/jenkins_home/.minikube#g' /tmp/kubeconfig-jenkins
sed -i "s#$(printf '%s' "$HOME/.minikube" | sed 's#/#\\/#g')#/var/jenkins_home/.minikube#g" /tmp/kubeconfig-jenkins

docker run -d --name jenkins-lab4 \
  --restart unless-stopped \
  --network lab4-net \
  -p 8081:8080 \
  --add-host=minikube:host-gateway \
  -v jenkins_home_lab4:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker:ro \
  -v /tmp/kubeconfig-jenkins:/var/jenkins_home/.kube/config:ro \
  -v "$HOME/.minikube:/var/jenkins_home/.minikube:ro" \
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

  # kubectl
  curl -L https://dl.k8s.io/release/v1.34.2/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl

  HELM_VERSION="v3.16.2"

  cd /tmp
  curl -fsSLo helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
  tar xzf helm.tar.gz
  mv linux-amd64/helm /usr/local/bin/helm
  chmod +x /usr/local/bin/helm
  rm -rf helm.tar.gz linux-amd64
'

echo "[i] Reiniciando el contenedor"
docker restart jenkins-lab4

echo "[i] Listo, Jenkins iniciado"
echo "http://localhost:8081"
echo "user: admin"
echo "pass: admin123"
