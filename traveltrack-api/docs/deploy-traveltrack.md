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

### 4.0 Iniciar Minikube

``` bash
make start-minikube
```

### 4.1 render

```bash
make render
```


### 4.2 aplicar

```bash
make apply
```

---

### 4.3 port-forward

``` bash
make port-forward
```

---

## 5) Test

Verificar que la aplicación responde correctamente:

```bash
make smoke
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

