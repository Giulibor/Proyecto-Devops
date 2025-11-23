

# Arquitectura y Decisiones Técnicas — TravelTrack API

## 1. Objetivo del documento

Describir las decisiones técnicas tomadas para cumplir con los requisitos del laboratorio: contenerización segura, despliegue reproducible, seguridad en varias capas, automatización y validación del entorno.

---

## 2. Componentes y decisiones principales

### 2.1 Node.js + TypeScript

**Qué es:** Plataforma para construir servicios HTTP ligeros y tipados.  

**Aplicación en el proyecto:** Se definió un microservicio Express con los endpoints requeridos. Los datos se mantienen en memoria según lo permitido en la consigna.

### 2.2 Docker e Imagen mínima

**Qué es:** Mecanismo de contenerización reproducible.  

**Aplicación en el proyecto:** Se usó un Dockerfile multi-stage, eliminando dependencias de build, sin usuario root y con una imagen final lo más liviana posible.

**Decisiones adicionales:**

- Eliminación de npm/npx del runtime para reducir superficie de ataque.
- Uso de COPY con `--chown` para mantener permisos coherentes con usuario no-root.
- Limpieza explícita de artefactos del build stage (node_modules, dependencias temporales).
- Validación con Dive para confirmar eficiencia de capas y ausencia de archivos residuales.

### 2.3 Publicación en GHCR

**Qué es:** Registro OCI dentro del ecosistema GitHub.  

**Aplicación en el proyecto:** La imagen se publica con tags inmutables y multi-arquitectura (amd64/arm64). Kubernetes toma la imagen directamente desde GHCR.

**Decisiones adicionales:**

- Se generaron tags inmutables basados en timestamp `YYYY.MM.DD.HH.MM` de forma automática.
- El Makefile persiste el tag en `.env` para asegurar reproducibilidad entre builds.
- Se actualiza automáticamente `values.yaml` vía YQ luego de publicar en GHCR.
- Separamos flujos: construcción local vs despliegue usando imagen de GHCR.

### 2.4 Helm

**Qué es:** Herramienta de plantillas para Kubernetes.  

**Aplicación en el proyecto:** Se generó un chart con Deployment, Service y ConfigMap. Helm permite cambiar el tag de la imagen sin editar múltiples YAML.

**Decisiones adicionales:**

- Helm se ejecuta mediante contenedor, evitando instalación en el host.
- El paso `render` permite inspeccionar el YAML final antes de aplicar.
- `config.APP_VERSION` se inyecta desde Makefile para mantener versiones sincronizadas.

### 2.5 Kubernetes (Deployment, Service, ConfigMap)

**Qué es:** Orquestador de contenedores estándar.  

**Aplicación en el proyecto:** Deployment con réplicas, Service estable tipo ClusterIP y ConfigMap para parámetros como versión y puerto. Todos los contenedores tienen requests/limits.

**Decisiones adicionales:**

- El Service se mantiene en ClusterIP para asegurar estabilidad de red interna.
- Todos los Pods tienen requests/limits obligatorios, alineados con políticas Kyverno.
- Limpieza de entorno mediante borrado completo del namespace.
- El smoke test integra automáticamente port‑forward + validación de endpoints.

### 2.6 Kyverno

**Qué es:** Motor de políticas para Kubernetes.  

**Aplicación en el proyecto:** Se aplicaron tres políticas obligatorias: prohibir `:latest`, exigir recursos y requerir `runAsNonRoot`. Se verificaron con despliegues buenos/malos.

**Decisiones adicionales:**

- Se detectaron problemas de instalación por CRDs con anotaciones >256KiB; se resolvió usando flujo delete+create en vez de usar apply.
- Se creó `kyverno-reset` para limpiar todas las ClusterPolicy del cluster.
- Los tests good/bad verifican enforcement real, no solo audit.

**Observaciones adicionales:**

- Durante pruebas reales, Kyverno dejó webhooks activos aun después de eliminar el namespace, lo que bloqueó operaciones como `kubectl delete namespace` por fallas en `validate.kyverno.svc-fail`.
- Se identificó la necesidad de remover manualmente `ValidatingWebhookConfiguration` y `MutatingWebhookConfiguration` para restaurar el funcionamiento normal del cluster.
- Esto evidencia que la desinstalación de Kyverno debe contemplar la limpieza explícita de webhooks además del namespace.


### 2.7 Auditorías de dependencias (npm audit)

**Qué es:** Análisis de vulnerabilidades del ecosistema npm.  

**Aplicación en el proyecto:** Se ejecutó `npm audit` y se guardó evidencia en `reports/npm-audit.txt`. Se revisaron y documentaron vulnerabilidades relevantes.

**Decisiones adicionales:**

- El reporte se guarda en JSON para filtrado automatizado con jq.

### 2.8 Trivy

**Qué es:** Scanner de vulnerabilidades para imágenes.  

**Aplicación en el proyecto:** Se escaneó la imagen final y se generó un resumen de HIGH/CRITICAL. La evidencia quedó en `reports/trivy-report.json`.

**Decisiones adicionales:**

- Se agregó target `trivy-scan` y `trivy-summary` al Makefile.
- Escaneo siempre contra GHCR para validar el pipeline completo.
- Se obliga uso de daemon Docker del host por requerir `/var/run/docker.sock`.

### 2.9 Análisis de imagen (Dive)

**Qué es:** Inspección de layers y eficiencia.  

**Aplicación en el proyecto:** Se revisaron capas, tamaños y archivos sobrantes. Se incluyó un resumen en `reports/dive.md`.

**Decisiones adicionales:**

- Target `dive-image` permite análisis directo desde GHCR.
- Validación real de eficiencia (98–99%).
- Confirmación de ausencia de artefactos de build y capas innecesarias.

### 2.10 KubeLinter

**Qué es:** Analizador estático de manifiestos Kubernetes.  

**Aplicación en el proyecto:** Se validó el YAML rendereado con Helm. Reporte en `reports/kubelinter.txt`.

**Decisiones adicionales:**

- El target autogenera `deploy/tt.yaml` si no existe.
- El análisis se ejecuta mediante contenedor oficial de KubeLinter.

### 2.11 Falco (seguridad en tiempo de ejecución)

**Qué es:** Monitor de actividades sospechosas en el cluster.  

**Aplicación en el proyecto:** Se instaló y se generó un evento controlado mediante `kubectl exec`. En Minikube/macOS Falco muestra limitaciones por BPF, pero la evidencia del flujo quedó en `reports/falco-event.log`.

**Decisiones adicionales:**

- Documentación de limitaciones reales de BPF en macOS/Minikube.

**Observaciones adicionales:**

- Se probaron distintos drivers: `ebpf` (falló al iniciar) y `modern-bpf` (inicializó correctamente pero con advertencias por falta de tracepoints en el kernel LinuxKit).
- El trigger original falló porque el contenedor tiene `readOnlyRootFilesystem`; se ajustó el evento sospechoso a un comando que no escribiera en disco (`id; sleep 1`).
- En este entorno, Falco no llega a registrar alertas aun recibiendo eventos, debido a limitaciones del kernel virtualizado en macOS/Docker Desktop.
- La instalación final se realiza mediante `helm template` + `kubectl apply`, evitando problemas de kubeconfig desde contenedores Helm.

### 2.12 Makefile

**Qué es:** Automatización declarativa de comandos.  

**Aplicación en el proyecto:** Centraliza build, publish, render, apply, escaneos, Kyverno, KubeLinter, Falco y limpieza. Facilita reproducibilidad del entorno.

**Decisiones adicionales:**

- Separación de flujos: `deploy-from-ghcr` (sin build) y `deploy-from-local-build`.
- Manejo robusto del Docker daemon: `use-host-docker` y `use-minikube-docker`.
- Integración de Trivy, Dive, KubeLinter, Kyverno y Falco en targets independientes.
- Endurecimiento del shell con `.SHELLFLAGS := -eu -o pipefail -c` para mayor confiabilidad.

**Observaciones adicionales:**

- El contenedor Helm utiliza `helm` como ENTRYPOINT, lo que generó errores del tipo `unknown command "helm"` al intentar ejecutar `helm helm ...`; se resolvió forzando `--entrypoint sh`.
- Se descubrió que Helm no persiste repositorios entre invocaciones `docker run`; se consolidó `repo add`, `repo update` y `template` en una sola ejecución dentro del mismo contenedor.
- La desinstalación de Kyverno solo eliminaba el namespace, dejando webhooks activos; esto afectó targets que usan `kubectl delete namespace`.
- El target `falco-trigger` fue ajustado para evitar errores de escritura y asegurar que el evento generara actividad detectable por Falco.

---

## 3. Decisiones clave

- Se evitaron YAML duplicados usando Helm como única fuente de verdad.
- Se usaron tags inmutables para eliminar ambigüedad entre builds.
- Se aplicó `runAsNonRoot` en la imagen y se reforzó con Kyverno.
- Se eligió multi-arch porque el host es ARM y Minikube utiliza arquitectura distinta.
- Todos los pasos operativos se encapsularon en Makefile para simplificar la entrega.
- Kyverno puede dejar webhooks activos si solo se elimina el namespace, bloqueando operaciones del API server.
- Falco con `modern-bpf` inicializa pero no registra alertas debido a la falta de tracepoints del kernel LinuxKit usado por Minikube en macOS.

---

## 4. Limitaciones conocidas

- Falco en macOS/Minikube no tiene soporte completo de BPF.
- El servicio usa almacenamiento en memoria según lo permitido por la consigna.
- Algunas herramientas (Helm, Trivy, YQ) se ejecutan mediante contenedores.

---

## 5. Cierre

El proyecto integra contenerización segura, despliegue automatizado, políticas, auditorías y evidencias completas en `reports/`. Este documento complementa al README y la guía de despliegue con el contexto necesario para comprender el diseño.
