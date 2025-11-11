# Guía de Deploy — TravelTrack API (Build + GHCR + Docker)

Esta guía describe el flujo estándar para **construir, publicar y probar la imagen de la API TravelTrack**, sin usar Kubernetes ni Helm.  
El proceso está completamente automatizado mediante el `Makefile`.

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
    
- Sube la imagen a `ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION.
    

---

## 3) Verificación de publicación

Inspeccionar el manifiesto publicado y confirmar las arquitecturas disponibles:

```bash
make imagetools-inspect
```

Debe mostrar al menos las variantes `linux/amd64` y `linux/arm64`.

---

## 4) Descargar y ejecutar la imagen publicada

### 4.1 Pull explícito del tag publicado

```bash
docker pull ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION_CURRENT
```

Esto descarga la imagen publicada desde GHCR para la arquitectura correspondiente a tu host.

---

### 4.2 Ejecutar el contenedor en el puerto 8080

```bash
docker run --rm --name traveltrack-api \
  -e APP_VERSION=${APP_VERSION:-1.0.0} \
  -p 8080:8080 \
  ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION_CURRENT
```

- `--rm`: elimina el contenedor al detenerlo.
    
- `-e APP_VERSION`: expone la versión de la aplicación.
    
- `-p 8080:8080`: mapea el puerto local 8080 al contenedor.
    

---

## 5) Test

Verificar que la aplicación responde correctamente:

```bash
curl -s http://localhost:8080/health
curl -s http://localhost:8080/api/version
```

- `/health`: debe devolver un estado OK.
    
- `/api/version`: debe reflejar la versión actual (`APP_VERSION` o `IMAGE_VERSION`).
    

---

**Resultado esperado:**  
El contenedor se levanta correctamente, expone los endpoints esperados y confirma que la imagen multi-arquitectura publicada en GHCR funciona sin dependencias externas.