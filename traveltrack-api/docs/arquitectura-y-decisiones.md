

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

### 2.3 Publicación en GHCR
**Qué es:** Registro OCI dentro del ecosistema GitHub.  
**Aplicación en el proyecto:** La imagen se publica con tags inmutables y multi-arquitectura (amd64/arm64). Kubernetes toma la imagen directamente desde GHCR.

### 2.4 Helm
**Qué es:** Herramienta de plantillas para Kubernetes.  
**Aplicación en el proyecto:** Se generó un chart con Deployment, Service y ConfigMap. Helm permite cambiar el tag de la imagen sin editar múltiples YAML.

### 2.5 Kubernetes (Deployment, Service, ConfigMap)
**Qué es:** Orquestador de contenedores estándar.  
**Aplicación en el proyecto:** Deployment con réplicas, Service estable tipo ClusterIP y ConfigMap para parámetros como versión y puerto. Todos los contenedores tienen requests/limits.

### 2.6 Kyverno
**Qué es:** Motor de políticas para Kubernetes.  
**Aplicación en el proyecto:** Se aplicaron tres políticas obligatorias: prohibir `:latest`, exigir recursos y requerir `runAsNonRoot`. Se verificaron con despliegues buenos/malos.

### 2.7 Auditorías de dependencias (npm audit)
**Qué es:** Análisis de vulnerabilidades del ecosistema npm.  
**Aplicación en el proyecto:** Se ejecutó `npm audit` y se guardó evidencia en `reports/npm-audit.txt`. Se revisaron y documentaron vulnerabilidades relevantes.

### 2.8 Trivy
**Qué es:** Scanner de vulnerabilidades para imágenes.  
**Aplicación en el proyecto:** Se escaneó la imagen final y se generó un resumen de HIGH/CRITICAL. La evidencia quedó en `reports/trivy-report.json`.

### 2.9 Análisis de imagen (Dive)
**Qué es:** Inspección de layers y eficiencia.  
**Aplicación en el proyecto:** Se revisaron capas, tamaños y archivos sobrantes. Se incluyó un resumen en `reports/dive.md`.

### 2.10 KubeLinter
**Qué es:** Analizador estático de manifiestos Kubernetes.  
**Aplicación en el proyecto:** Se validó el YAML rendereado con Helm. Reporte en `reports/kubelinter.txt`.

### 2.11 Falco (seguridad en tiempo de ejecución)
**Qué es:** Monitor de actividades sospechosas en el cluster.  
**Aplicación en el proyecto:** Se instaló y se generó un evento controlado mediante `kubectl exec`. En Minikube/macOS Falco muestra limitaciones por BPF, pero la evidencia del flujo quedó en `reports/falco-event.log`.

### 2.12 Makefile
**Qué es:** Automatización declarativa de comandos.  
**Aplicación en el proyecto:** Centraliza build, publish, render, apply, escaneos, Kyverno, KubeLinter, Falco y limpieza. Facilita reproducibilidad del entorno.

---
## 3. Decisiones clave
- Se evitaron YAML duplicados usando Helm como única fuente de verdad.
- Se usaron tags inmutables para eliminar ambigüedad entre builds.
- Se aplicó `runAsNonRoot` en la imagen y se reforzó con Kyverno.
- Se eligió multi-arch porque el host es ARM y Minikube utiliza arquitectura distinta.
- Todos los pasos operativos se encapsularon en Makefile para simplificar la entrega.

---
## 4. Limitaciones conocidas
- Falco en macOS/Minikube no tiene soporte completo de BPF.
- El servicio usa almacenamiento en memoria según lo permitido por la consigna.
- Algunas herramientas (Helm, Trivy, YQ) se ejecutan mediante contenedores.

---
## 5. Cierre
El proyecto integra contenerización segura, despliegue automatizado, políticas, auditorías y evidencias completas en `reports/`. Este documento complementa al README y la guía de despliegue con el contexto necesario para comprender el diseño.