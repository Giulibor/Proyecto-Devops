# Guía de Deploy — TravelTrack API  

---

## 0. Por dónde comenzar?

Una vez descargado el repositorio `https://github.com/Giulibor/Proyecto-Devops.git`
Desde la terminal, situarse en la carpeta `Proyecto-Devops/traveltrack-api/`

---

## 1. Empaquetado y Publicación de Imágenes (GHCR)

### 1.1 Credenciales GHCR

Requisitos, tener ya los siguientes datos en `.env`:

- `GH_USER`: tu usuario de GitHub.
- `GH_TOKEN`: token personal con permiso `write:packages`.

### 1.2 Publicación completa (multi-arch)  

Para construir multi-arquitectura (amd64 + arm64), publicar en GHCR **y actualizar el chart Helm**:

```bash
make ghcr-publish
```

Este comando:

- Genera `IMAGE_VERSION` si está en `auto`.
- Publica `ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION`.
- Actualiza `charts/traveltrack-api/values.yaml` (repository + tag).

---

### 1.3 Verificación de la imagen publicada

```bash
make imagetools-inspect
```

Debe listar al menos:

- `linux/amd64`
- `linux/arm64`

---

## 2. Deploy en Kubernetes (Minikube + Helm)

Para desplegar usando **la imagen ya publicada en GHCR** y registrada en `values.yaml`:

```bash
make deploy-from-ghcr
```

Este comando hace:

1. **start-minikube**   
    - Inicia el cluster Minikube (si no está iniciado).
2. **render**
    - Genera `deploy/tt.yaml` a partir del chart Helm.
    - Usa `values.yaml`, donde ya está configurado:
        - el `repository` de GHCR
        - el `tag` de la imagen publicada
3. **apply**
    - Crea el namespace `traveltrack` si no existe.
    - Aplica `deploy/tt.yaml` (deployment, service, configmap, etc.).
    - Kubernetes descarga automáticamente la imagen desde GHCR.
4. **smoke**
    - Ejecuta un test rápido:
        - `/health`
        - `/api/version`
    - Hace port-forward temporal y verifica que la app responde.

---

## 3. Kyverno — Validación de Políticas

> No requiere que la app esté corriendo.

### 3.1 Instalar Kyverno en el cluster

```bash
make kyverno-install-kubectl
```

### 3.2 Aplicar políticas

```bash
make kyverno-apply
```

Reporte en:  
`reports/kyverno.log`

### 3.3 Validación manual (opcional)

```bash
make kyverno-test-bad
make kyverno-test-good
make kyverno-clean
```

### 3.4 Desinstalar Kyverno

```bash
make kyverno-uninstall
```

---

## 4. Auditorías de Seguridad

### 4.1 npm audit (dependencias Node)

> No requiere que la app esté corriendo.

Instalar dependencias:

```bash
npm install
```

Generar reporte:

```bash
npm audit --json > reports/npm-audit.txt
```

Visualizar:

```bash
cat reports/npm-audit.txt | jq '.'
```

---

## 4.2 Trivy (vulnerabilidades de la imagen)

> No requiere que la app esté corriendo.

Ejecutar análisis:

```bash
make trivy-scan
```

Filtrar HIGH + CRITICAL:

```bash
make trivy-summary
```

---

### 4.3 Dive (análisis de capas)

> No requiere que la app esté corriendo.

Ejecutar:

```bash
make dive-image
```

**Tips rápidos para usar Dive:**

1. **Cambiar entre vistas**
    Usá las teclas **Tab** y **C** para alternar entre:
    - Árbol de capas (Layer Tree)
    - Contenido del filesystem
    - Vista agregada de cambios y archivos duplicados
        Ideal para encontrar qué layer aporta más peso o qué archivos se repiten.
2. **Filtrar archivos por cambio o tamaño**
    Presioná **F** para activar filtros (por tipo de cambio, tamaño, etc.).
    Muy útil para detectar:
    - módulos npm innecesarios
    - archivos que quedaron de más en el build
    - dependencias duplicadas
3. **Interpretar el “Image efficiency score”**
    Dive te da un puntaje (0–100%).
    Si el score es alto (90%+), tu Dockerfile está bien optimizado:
    - pocas capas inútiles
    - poco contenido duplicado
    - pasos de build razonables.

---

## 5. KubeLinter — Análisis de Manifiestos Kubernetes

> No requiere que la app esté corriendo.

El target genera automáticamente `deploy/tt.yaml` si no existe.

```bash
make kubelinter-scan
```

Salida:

`reports/kubelinter.txt`

---

## 6. Falco — Detección de Intrusiones (Runtime Security)

> Requiere que la app ya esté corriendo en Minikube.

### 6.1 Instalar Falco

```bash
make falco-install
```

### 6.2 Generar un evento sospechoso y exportar logs

```bash
make falco-trigger
sleep 60
make falco-logs
```

Salida:

`reports/falco-event.log`

### 6.3 Desinstalar Falco (se elimina el namespace)

```bash
make falco-uninstall
```

#### Nota sobre limitaciones  

En Minikube sobre macOS el kernel virtualizado no expone todos los tracepoints necesarios para BPF, por lo que Falco registra errores `libbpf` y no dispara todas las reglas.  
Aun así:
- La instalación funciona
- La simulación de evento es válida
- Se generan logs de evidencia

---

## 7. Limpieza del entorno

### 7.1 Eliminar namespace

```bash
kubectl delete namespace traveltrack
```

### 7.2 Apagar Minikube

```bash
make stop-minikube
```

---

## 8. Ayuda memoria (Docker Daemon)

Cambiar Docker CLI al daemon de Minikube:

```bash
eval $(minikube docker-env)
```

Restaurar Docker CLI del host:

```bash
eval $(minikube docker-env -u)
```

---

## 9. Estado de Pendientes

- [ ] Mejorar smoke test (agregar endpoints adicionales)
- [ ] Renombrar `tt.yaml` → `traveltrack.yaml`
