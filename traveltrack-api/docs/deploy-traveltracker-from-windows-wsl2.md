# Guía de despliegue desde Windows / WSL2

## 1. Requisitos previos
- **Windows 10/11** con **WSL2** habilitado.
- **Ubuntu 20.04/22.04** instalado desde Microsoft Store.
- **Docker Desktop** instalado y con integración activada para WSL2.
- **kubectl**, **minikube**, **make**, **git** instalados dentro del entorno Ubuntu-WSL2.
- Verificar conexión entre Docker Desktop y WSL2.

### Verificación rápida
```bash
make -f Makefile.windows win-doctor
```

---

## 2. Clonar y preparar el entorno
Clonar el repositorio dentro del entorno de WSL (no en `C:\`).

```bash
cd ~
git clone https://github.com/<tu-org>/Proyecto-Devops.git
cd Proyecto-Devops/traveltrack-api
```

Cargar variables de entorno:
```bash
cp .env.example .env
nano .env    # Completar GH_USER, GH_TOKEN, etc.
```

---

## 3. Flujo recomendado (sin almacenamiento local)
Este flujo utiliza **Buildx multi-arch** y despliega directamente desde **GHCR**.

```bash
make -f Makefile.windows deploy-from-ghcr
```

### Qué hace internamente
1. Construye y publica imagen multi-arch (`amd64`, `arm64`) a GHCR.
2. Renderiza el chart Helm con `image.pullPolicy=Always`.
3. Aplica los manifiestos al cluster (`kubectl apply`).
4. Ejecuta pruebas básicas de salud (`make smoke`).

---

## 4. Alternativas locales
Si preferís trabajar sin publicar la imagen en GHCR:

### Build dentro de Minikube
```bash
make -f Makefile.windows build-in-minikube
make -f Makefile.windows render
make -f Makefile.windows apply
```

### Build en host (Docker Desktop)
```bash
make -f Makefile.windows use-host-docker
make -f Makefile.windows build-host
```

---

## 5. Pruebas y validación
Probar endpoints principales:
```bash
make -f Makefile.windows smoke
```

---

## 6. Limpieza
Eliminar recursos del cluster y detener Minikube:
```bash
make -f Makefile.windows uninstall
make -f Makefile.windows delete-ns
make -f Makefile.windows stop-minikube
```

---

## 7. Notas operativas
- Si `docker run -v "$PWD":/work` falla, agregar:
  ```bash
  export MSYS_NO_PATHCONV=1
  ```
- Si el Pod queda en `ImagePullBackOff`, asegurate de haber ejecutado `deploy-from-ghcr`.
- Confirmar daemon activo:
  ```bash
  docker info | grep -i name
  ```

---

## 8. Resumen
Este procedimiento permite desplegar la aplicación **TravelTrack API** desde **Windows/WSL2** usando los mismos flujos DevOps que en macOS/Linux.  
La diferencia principal radica en la compatibilidad de rutas y la interacción con **Docker Desktop** como daemon principal.
