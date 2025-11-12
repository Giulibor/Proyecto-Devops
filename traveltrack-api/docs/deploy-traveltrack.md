# Guía de Deploy — TravelTrack API (Build + GHCR + Docker + K8s plano)

Esta guía describe el flujo estándar para **construir, publicar y probar la imagen de la API TravelTrack**, primero con Docker y luego desplegarla en **Kubernetes** sin usar Helm.  
El proceso está automatizado mediante el `Makefile` y manifiestos YAML.

---

## 0) (Opcional) Requisitos rápidos

Verificar que las variables y versiones estén correctamente configuradas:

```bash
make print-version
```

---

## 1) Preparación

Cargar credenciales y validar el acceso a GitHub Container Registry (GHCR):

```bash
echo "$GH_USER"
test -n "$GH_TOKEN" && echo "OK TOKEN" || echo "FALTA TOKEN"
make ghcr-login
```

- `GH_USER`: usuario de GitHub.
    
- `GH_TOKEN`: token personal con permisos `write:packages`.
    
- `make ghcr-login`: autentica el cliente Docker en GHCR.
    

---

## 2) Build multi-arquitectura + Push

Construir la imagen para `amd64` y `arm64`, y publicarla directamente en GHCR:

```bash
make buildx-push
```

Este comando:

- Genera automáticamente `IMAGE_VERSION` (fecha/hora si está en `auto`).
    
- Compila para múltiples arquitecturas (`linux/amd64`, `linux/arm64`).
    
- Sube la imagen a `ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION`.
    

---

## 3) Verificación de publicación

Inspeccionar el manifiesto publicado y confirmar las arquitecturas disponibles:

```bash
make imagetools-inspect
```

Debe mostrar al menos las variantes `linux/amd64` y `linux/arm64`.

---

## 4) Despliegue en Kubernetes (YAML plano)

### 4.1 Aplicar y verificar

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

kubectl -n traveltrack get all
```

- `namespace.yaml`: crea el namespace dedicado.
    
- `configmap.yaml`: define variables `APP_VERSION` y `PORT`.
    
- `deployment.yaml`: despliega la imagen publicada en GHCR.
    
- `service.yaml`: expone el servicio interno tipo `ClusterIP`.
    

---

### 4.2 port-forward

```bash
kubectl -n traveltrack port-forward svc/traveltrack-api 8080:8080
```


---

## 5) Test final (local o cluster)

Verificar que la aplicación responde correctamente:

```bash
curl -s http://localhost:8080/health
curl -s http://localhost:8080/api/version
```

- `/health`: debe devolver un estado OK.
    
- `/api/version`: debe reflejar la versión actual (`APP_VERSION` o `IMAGE_VERSION`).

Si las respuestas son correctas, la aplicación está corriendo dentro del cluster.

---
### 6. Limpieza del entorno

#### 6.1 Borrar el namespace de travletrack

```bash
kubectl delete namespace traveltrack
```

#### 6.2 Apagar minikube

```bash
make stop-minikube
```

