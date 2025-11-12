# Infrastructura - Mapa Conceptual

## 🗺️ Mapa de Integración

### 1. **Terraform (Infraestructura como Código - IaC)**

* Define la infraestructura necesaria para correr la aplicación.
* Ejemplo:

  * Crear un **servidor local** o en la nube.
  * Provisionar **Docker** y configurar redes/volúmenes.
  * O directamente definir un **cluster de Kubernetes** (EKS, GKE, AKS) o levantar servicios auxiliares (DBs, buckets, etc.).

👉 Es la base: “dónde” se van a correr los contenedores.

---

### 2. **Docker (Contenerización)**

* Empaqueta la aplicación en imágenes portables.
* Usa un `Dockerfile` → define dependencias, variables de entorno, comandos de arranque.
* Resultado: una imagen que puede publicarse en un **registry** (ej: Docker Hub, ECR).

👉 Es el “qué” vamos a desplegar: la aplicación lista para correr.

---

### 3. **Minikube / Kubernetes (Orquestación)**

* Minikube: entorno local para simular un cluster Kubernetes.
* Kubernetes: orquesta el despliegue de contenedores en pods.
* Objetos clave:

  * **Deployment** → controla versiones, escalado, rollouts/rollbacks.
  * **Service** → expone pods de forma estable.
  * **ConfigMap/Secret** → maneja configuración sin modificar la imagen.
  * **Ingress** → entrada HTTP al cluster.

👉 Es el “cómo” se ejecuta en producción: gestiona replicas, disponibilidad, upgrades.

---

### 4. **Jenkins (CI/CD)**

* Automatiza el pipeline:

  1. **Build** → clona el repo, corre tests, genera imagen Docker.
  2. **Push** → sube la imagen al registry.
  3. **Deploy** → usa `kubectl` o manifiestos IaC para aplicar en Kubernetes (ej: Minikube en dev, cluster en prod).
* Integra con **Terraform** (ejecuta `terraform apply` en stages de infraestructura).
* Integra con **Docker** (build & push).
* Integra con **Kubernetes** (deploy & update).

👉 Es el “cuándo” y “en qué orden”: automatiza todo el ciclo.

---

## 🔗 Resumen visual (flujo simplificado)

```text
[Terraform] → crea infraestructura (VMs, cluster, redes, volúmenes)
      ↓
[Docker] → build imagen de la app + push al registry
      ↓
[Jenkins] → pipeline CI/CD
   ├─ Build & Test (con Docker)
   ├─ Deploy Infra (con Terraform)
   └─ Deploy App (con kubectl a Kubernetes/Minikube)
      ↓
[Minikube/Kubernetes] → orquesta contenedores, gestiona versiones y disponibilidad
```
