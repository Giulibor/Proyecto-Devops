

# Jenkins Configuration for Proyecto-Devops

Este proyecto utiliza Jenkins configurado mediante **Pipeline as Code** usando el archivo `Jenkinsfile`. Las variables de entorno necesarias son leídas desde un archivo `.env`, permitiendo flexibilidad y portabilidad.

## Requisitos previos

- Jenkins instalado y en ejecución.
- Plugins necesarios:
  - **Pipeline**
  - **Credentials**
  - **Configuration as Code**
- Docker instalado y accesible desde Jenkins.
- Minikube instalado y configurado.
- (Opcional) Terraform instalado si se desea automatizar infraestructura.

## Configuración de credenciales

Agregue las siguientes credenciales en Jenkins (`Manage Jenkins` > `Credentials`):

| ID                   | Tipo                | Descripción                        |
|----------------------|---------------------|------------------------------------|
| dockerhub-creds      | Username/Password   | Credenciales de DockerHub          |
| kubeconfig-minikube  | Secret file         | Archivo kubeconfig de Minikube     |

## Archivo .env

Cree un archivo `.env` en la raíz del proyecto con las variables necesarias. Ejemplo:

```env
# .env.example
APP=myapp
VERSION=1.0.0
DOCKERHUB_USER=usuario
DOCKERHUB_REPO=repo
KUBE_NAMESPACE=default
DEPLOY_STRATEGY=rolling
RUN_TERRAFORM=false
```

## Ejecución del pipeline

1. Cree un **Multibranch Pipeline Job** en Jenkins.
2. Configure el job para apuntar a este repositorio (GitHub, GitLab, etc.).
3. Jenkins detectará automáticamente el `Jenkinsfile` y construirá los branches.
4. Los parámetros del pipeline incluyen:
   - `APP`: nombre de la aplicación a desplegar.
   - `VERSION`: versión/tag de la imagen.
   - `DEPLOY_STRATEGY`: estrategia de despliegue (por ejemplo, `rolling`, `recreate`).
   - `RUN_TERRAFORM`: (bool) ejecutar o no el paso de Terraform.

## Buenas prácticas

- **No** suba el archivo `.env` al repositorio (agregue a `.gitignore`).
- Utilice el sistema de credenciales de Jenkins para datos sensibles.
- Mantenga consistencia en los nombres de variables y credenciales.
- Para agregar nuevas aplicaciones, extienda el pipeline y agregue las variables necesarias en `.env`.

---

> Equipo UCU DevOps - Curso 2025