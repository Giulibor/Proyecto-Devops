# Guía de despliegue y pruebas – TravelTrack API

Esta guía explica cómo **empaquetar** y **probar** la app en Kubernetes **sin instalar Helm en ls Mac**, usando un contenedor de Helm para renderizar el chart a YAML y `kubectl` para aplicarlo.

---

## 1) Prerrequisitos

* Docker, Minikube, kubectl.
* Repositorio `https://github.com/Giulibor/Proyecto-Devops.git` clonado.
* Trabajar desde el direcotrio `traveltrack-api`.

---

## 2) Iniciar Minikube

```bash
minikube start --driver=docker --memory=2048 --cpus=2
minikube status
kubectl get nodes
```

---

## 3) Construir la imagen (elegí UNA de estas dos variantes)

### Build **dentro de Minikube**

> La imagen queda disponible directamente en el cluster.

```bash
# Cambiar Docker CLI para usar el daemon de Minikube
eval $(minikube docker-env)

# Build (estando en la raíz del repo)
export VERSION=0.1.0
docker build -t traveltrack-api:$VERSION ./traveltrack-api

# (Opcional) verificar que la imagen quedó en el daemon de minikube
minikube ssh docker images | grep traveltrack
```

---

## 4) Renderizar el chart Helm a YAML (sin Helm instalado)

```bash
# usar Docker del host para montar la carpeta
eval $(minikube docker-env -u)   

docker run --rm -v "$PWD":/work -w /work \
  alpine/helm:3.15.3 \
  template tt ./charts/traveltrack-api \
  -n traveltrack \
  --values ./charts/traveltrack-api/values.yaml \
  > ./deploy/tt.yaml
```

Esto genera `tt.yaml` con **todos los manifiestos** listos para aplicar.

---

## 5) Aplicar el YAML al cluster

```bash
# Cambiar Docker CLI para usar el daemon de Minikube
eval $(minikube docker-env)

kubectl create namespace traveltrack --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n traveltrack -f ./deploy/tt.yaml
kubectl get deploy,po,svc -n traveltrack
```

---

## 6) Probar la API

```bash
kubectl -n traveltrack port-forward deploy/tt-traveltrack-api 8080:8080 &
sleep 2
echo "[health]:"
curl -s localhost:8080/health
echo "[version]:"
curl -s localhost:8080/api/version
echo "[travle-request test]:"
curl -s -X POST localhost:8080/api/travel-requests \
  -H 'content-type: application/json' \
  -d '{"employee":"Ana López","destination":"Madrid","days":4}'
curl -s localhost:8080/api/travel-requests
```

---

## 7) Troubleshooting rápido

| Síntoma                                            | Posible causa                                                                           | Fix                                                                                            |
| -------------------------------------------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `Error: path "./charts/traveltrack-api" not found` | El contenedor no ve el repo montado. Usaste el daemon de Minikube para el `docker run`. | Ejecutá `eval $(minikube docker-env -u)` y volvé a correr el `docker run ... helm template`.   |
| `ImagePullBackOff`                                 | El cluster no tiene la imagen.                                                          | Variante A: build dentro de Minikube. Variante B: `minikube image load traveltrack-api:0.1.0`. |
| `CrashLoopBackOff`                                 | App no arranca o puerto incorrecto.                                                     | `kubectl logs -n traveltrack deploy/tt-traveltrack-api`. Chequeá `PORT` y probes.              |
| `/health` no responde                              | Probes/puertos mal.                                                                     | Confirmá `config.port` y `service.port` en `values.yaml` (8080).                               |
| `helm: repo charts not found`                      | Usaste `charts/traveltrack-api` sin `./`.                                               | Usar **ruta local**: `./charts/traveltrack-api`.                                               |

---

## 8) Limpieza

```bash
kubectl delete -n traveltrack -f ./deploy/tt.yaml
kubectl delete ns traveltrack
# (opcional)
minikube stop
```

---

## 9) Resumen de alternancia Docker (mental model)

* **Build imágenes**

  * Dentro del cluster → `eval $(minikube docker-env)` + `docker build ...`
  * En host + cargar → `eval $(minikube docker-env -u)` + `docker build ...` + `minikube image load ...`

* **Render Helm en contenedor** (monta el repo con `-v "$PWD"`):
  → **Siempre con Docker del host**: `eval $(minikube docker-env -u)`

---

### 10) Imagen pública del proyecto

La imagen está disponible en GitHub Container Registry:

```bash
docker pull ghcr.io/cardo88/traveltrack-api:0.1.0
```

El Helm chart (`make render`) y los manifiestos (`tt.yaml`) la utilizan mediante tag inmutable.
