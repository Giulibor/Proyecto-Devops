💯 Exacto, muy bien que lo notaste — estás pensando con mentalidad DevOps de verdad 👏
# Deploy

## 🚀 0) Iniciar Minikube (si no está corriendo)

```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

Esto crea el cluster y levanta el daemon Docker interno que usa K8s.
Podés verificarlo con:

```bash
minikube status
kubectl get nodes
```

Deberías ver el nodo `minikube` en estado `Ready`.

---

## 🔄 1) Usar el Docker dentro de Minikube

Por defecto, cuando hacés `docker build`, estás usando **el Docker del host**.
Para que la imagen quede *dentro del entorno de Minikube* (sin necesidad de push/pull a un registry), ejecutá:

```bash
eval $(minikube docker-env)
```

Esto cambia temporalmente las variables de entorno:

* `DOCKER_HOST`
* `DOCKER_CERT_PATH`
* `DOCKER_TLS_VERIFY`

Y hace que **tu consola actual use el Docker daemon interno de Minikube**.

Podés comprobarlo con:

```bash
docker info | grep -i "name"
```

Debería mostrar algo como: `Name: minikube`.

---

## 🧱 2) (Re)build de la imagen dentro del daemon de Minikube

```bash
export VERSION=0.1.0
docker build -t traveltrack-api:$VERSION ./traveltrack-api
```

Ahora la imagen queda disponible directamente dentro del Minikube, sin hacer `minikube image load`.

Podés comprobarlo:

```bash
minikube ssh docker images | grep traveltrack
```

---

## ⚙️ 3) Instalar el chart con Helm

(Si ya hiciste estos pasos, solo confirmá.)

```bash
kubectl create namespace traveltrack || true
helm install tt charts/traveltrack-api -n traveltrack
kubectl get all -n traveltrack
```

---

## 🔎 4) Port-forward y test de endpoints

```bash
kubectl -n traveltrack port-forward deploy/tt-traveltrack-api 8080:8080 &
sleep 3
curl -s localhost:8080/health
curl -s localhost:8080/api/version
```

Deberías obtener:

```json
{"status":"ok"}
{"version":"0.1.0"}
```

---

## 🧹 5) (Opcional) Volver al Docker local

Si luego querés volver a tu daemon normal:

```bash
eval $(minikube docker-env -u)
```

---

✅ **Resumen conceptual**

* `minikube start` → levanta el cluster.
* `eval $(minikube docker-env)` → redirige Docker CLI hacia el daemon dentro del cluster.
* `docker build` → construye la imagen *dentro de Minikube*.
* `helm install` → despliega usando esa imagen local (sin registry).
* `curl /health` → verifica que todo anda.

---

¿Querés que te prepare un bloque para agregar esto al README bajo “Smoke test con Minikube” (con todos los comandos listos y numerados)?
