# Guía de despliegue y pruebas – TravelTrack API

Este documento explica el flujo recomendado para desplegar la API TravelTrack usando GHCR como registro principal, con soporte para imágenes multi-arquitectura y despliegue directo desde el registry. También incluye alternativas para desarrollo local y pruebas.

> **Compatibilidad Windows / WSL2**
> Este procedimiento fue validado en macOS/Linux. En Windows se recomienda ejecutar desde **WSL2 (Ubuntu)** y usar el **Makefile específico**:
>
> - Guía: `docs/deploy-traveltracker-from-windows-wsl2.md`
> - Makefile: `make -f Makefile.windows <target>`
>
> Ejemplos:
> ```bash
> make -f Makefile.windows doctor
> make -f Makefile.windows deploy-from-ghcr
> ```

---

## 1) Preparación

### Variables y entorno

Las variables principales se definen en el archivo `.env`:

- `APP_VERSION`: versión lógica de la API (ej. `1.0.0`).
- `IMAGE_VERSION`: versión de imagen (ej. `YYYY.MM.DD.HH.MM` o `auto`).
- `NAMESPACE`: namespace Kubernetes (por defecto `traveltrack`).

### Comando rápido: verificar versiones y entorno

```bash
make print-version
make doctor
```

`print-version` muestra las variables actuales que se usarán en el pipeline.  
`doctor` valida que las herramientas necesarias estén instaladas y configuradas correctamente.

---

## 2) Build y publicación multi-arch (recomendado)

Este flujo construye imágenes multi-arquitectura (`linux/amd64, linux/arm64`) y las publica en GitHub Container Registry (GHCR), sin almacenar la imagen localmente.

### Comando rápido: build y push multi-arch

```bash
make buildx-push
```

Este target usa Docker Buildx para:

- Construir imágenes multi-arquitectura.
- Etiquetar con `IMAGE_VERSION`.
- Publicar directamente en GHCR bajo `ghcr.io/$GH_USER/traveltrack-api`.

### Comando rápido: publicar en GHCR (solo tag y push)

```bash
make ghcr-publish IMAGE_VERSION=<opcional>
```

Permite publicar una imagen ya construida y etiquetada en GHCR.

> **Nota:** Para usar estos comandos, exporta las credenciales:
> ```bash
> export GH_USER=<tu_usuario_github>
> export GH_TOKEN=<tu_token_github>
> ```

---

## 3) Deploy desde GHCR (flujo real)

Para desplegar en Kubernetes usando la imagen publicada en GHCR, se recomienda este flujo.

### Comando rápido: renderizar y aplicar manifiestos

```bash
make deploy-from-ghcr
```

Este target:

- Renderiza los manifiestos Helm con `image.pullPolicy=Always` para asegurar que siempre se use la imagen del registry.
- Aplica el manifiesto al cluster en el namespace configurado.

---

## 4) Alternativas locales

Para desarrollo offline o pruebas rápidas, existen opciones para construir y usar la imagen localmente sin pasar por GHCR.

### Build dentro de Minikube (sin push)

```bash
make build-in-minikube
```

Construye la imagen directamente en el daemon Docker de Minikube, disponible para el cluster sin necesidad de push ni carga adicional.

### Build en el host y cargar a Minikube

```bash
make use-host-docker
make build-host
```

Construye la imagen en el Docker del host y luego la carga al cluster Minikube con:

```bash
minikube image load traveltrack-api:"$IMAGE_VERSION"
```

---

## 5) Test y validación

Para validar que la API está funcionando correctamente, se puede ejecutar:

```bash
make smoke
```

Este comando:

- Realiza un port-forward temporal al pod.
- Consulta endpoints clave como `/health` y `/api/version`.
- Confirma que la API responde y reporta su versión.

---

## 6) Cleanup

Para limpiar los recursos del cluster y detener Minikube:

```bash
make uninstall
make delete-ns
make stop-minikube
```

- `uninstall` elimina los recursos aplicados.
- `delete-ns` borra el namespace completo.
- `stop-minikube` detiene el cluster local.

---

## 7) Notas operativas y diagnóstico

- Si un `docker run -v "$PWD":/work` no accede a tu código, puede ser porque el CLI apunta al daemon Docker de Minikube. Regresa al Docker del host con:

  ```bash
  eval $(minikube docker-env -u)
  ```

- Si el Pod queda en estado `ImagePullBackOff`, significa que el cluster no puede obtener la imagen. Soluciones:

  - Usar build dentro de Minikube (`make build-in-minikube`).
  - Cargar la imagen localmente (`minikube image load`).
  - Usar imágenes publicadas en GHCR.

- Para inspeccionar un manifest multi-arch publicado:

  ```bash
  docker buildx imagetools inspect ghcr.io/$GH_USER/traveltrack-api:"$IMAGE_VERSION"
  ```

---

## 8) Resumen técnico

- **Docker Buildx**: construcción y publicación multi-arquitectura en GHCR.
- **GitHub Container Registry (GHCR)**: registro principal para imágenes inmutables y multi-arch.
- **Minikube**: cluster local con daemon Docker alternativo para desarrollo offline.
- **Helm (contenedor)**: renderizado de manifiestos Kubernetes sin instalar Helm localmente.
- **kubectl**: gestión y aplicación de recursos en Kubernetes.

Este flujo prioriza reproducibilidad, portabilidad y despliegue seguro desde un registry confiable.