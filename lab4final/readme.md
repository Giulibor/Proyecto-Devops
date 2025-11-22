### Pasos para configurar Jenkins

1.  Abrí Jenkins en el navegador
    - `http://localhost:8081`

2. Logueate con el usuario automático
    - Usuario: `admin`
    - Contraseña: `admin123`
3.  Creá el job de tipo Pipeline
    - Menú superior: “Nuevo Tarea” / “New Item”
    - En “Enter an item name”: escribí `lab4-pipeline`

    - En la lista de tipos, seleccioná “Pipeline” (no “Estilo libre / Freestyle”)

    - Botón OK

5.  Configurá el Pipeline con tu repositorio y Jenkinsfile
    En la pantalla de configuración del job:

    - Dejá la sección “General” como está (podés poner descripción si querés).

    - Bajá hasta la sección “Pipeline” (al final de la página):

    - Definition / Definición:
        - Pipeline script from SCM

    - SCM:
        - Git

    - Repository URL:
        - https://github.com/Giulibor/Proyecto-Devops.git

    - Credentials:
        - vacío

    - Branch Specifier (Branches to build):
        - `*/lab4coco`

    - Script Path:
        - `lab4final/Jenkinsfile`

    - Botón Guardar (Save).

6. Ejecutá el pipeline

    - Entrás al job `lab4-pipeline`.

    - Clic en “Build Now” / “Construir ahora”.

7. Revisá el log del pipeline

    - En la columna izquierda, abajo de “Build History”, clic en el número de build (por ejemplo #1).

    - Clic en “Console Output / Salida de consola”.

    - Verificá que se ejecuten en orden:

        - Checkout del repo

        - Semgrep

        - Snyk

        - Build Angular

        - Build Docker image

        - helm upgrade --install ...

## Descripción general del proyecto

El proyecto consiste en implementar un flujo completo de integración continua, entrega continua y seguridad integrada (DevSecOps) para una aplicación Angular llamada snake-app. Se utilizan contenedores Docker, un cluster Kubernetes desplegado con Minikube, plantillas Helm para gestionar el despliegue, Jenkins como herramienta principal de CI/CD y un conjunto de herramientas de seguridad y monitoreo: Semgrep, Snyk, Kyverno, Falco, Prometheus y Grafana.

El objetivo es que cada cambio en el repositorio active un pipeline que analice el código, valide dependencias, construya la aplicación, genere una imagen Docker válida, la despliegue en Kubernetes y quede monitoreada por Prometheus y Grafana, mientras Kyverno aplica políticas de seguridad y Falco detecta eventos maliciosos en tiempo de ejecución.

## Arquitectura final del sistema

### La arquitectura incluye:

- Una aplicación frontend Angular servida mediante nginx-unprivileged.

- Un cluster Kubernetes local proporcionado por Minikube.

- Jenkins ejecutando un pipeline de CI/CD con stages de análisis, construcción y despliegue.

- Un despliegue Helm que instala la aplicación en el namespace lab4.

- Un Ingress administrado por ingress-nginx instalado mediante Helm.

- Prometheus obteniendo métricas tanto del cluster como de la aplicación.

- Grafana mostrando un dashboard personalizado.

- Kyverno aplicando políticas de seguridad declarativas a nivel de cluster.

- Falco monitoreando actividad sospechosa o anómala a nivel de node runtime.

La comunicación se da de la siguiente forma: el desarrollador hace un commit; Jenkins obtiene el código, ejecuta los análisis, construye la imagen dentro del daemon de Docker de Minikube, aplica Helm y despliega la app. Prometheus scrapea la aplicación y el cluster. Grafana muestra métricas. Kyverno valida configuraciones y bloquea pods ilegales. Falco detecta comportamientos inseguros o extraños y genera alertas.

## Pipeline implementado

### El pipeline de Jenkins definido en lab4final/Jenkinsfile contiene las etapas requeridas por la consigna:

1. Checkout del repositorio proveniente de GitHub.
2. Análisis estático con Semgrep, usando reglas automáticas y con el flag `--error` para que el pipeline falle si hay findings de severidad bloqueante. El reporte se genera en `reports/semgrep-report.txt`.
3. Análisis de dependencias con Snyk sobre el `package.json` de la aplicación Angular. El reporte se guarda en `reports/snyk-report.json`. La severidad mínima configurada es critical, por lo que el pipeline falla si existe una vulnerabilidad crítica.
4. Instalación y compilación de la aplicación Angular usando `npm ci` y `npm run build` en modo producción.
5. Construcción de la imagen Docker usando el daemon interno de Minikube mediante `eval "$(minikube docker-env)"`. La imagen se genera con un tag fijo (por ejemplo `snake-app:1.0.3`).
6. Despliegue mediante Helm usando `helm upgrade --install`, aplicando `values.yaml` y `values-dev.yaml` y actualizando la imagen con el tag correspondiente.
7. Archivado de todos los reportes generados.

El pipeline funciona de principio a fin y detiene la ejecución si aparecen vulnerabilidades críticas o findings bloqueantes de Semgrep, cumpliendo el requisito explícito de la consigna.

## Métricas y dashboard de Grafana

Prometheus está instalado en el cluster y configurado para obtener métricas tanto de Kubernetes como de la aplicación snake-app. La aplicación debe exponer un endpoint de métricas o integrarse con un mecanismo similar, lo cual permite medir:

- Número de solicitudes por segundo (RPS).

- Latencia de respuesta.

- Uso de CPU y memoria por pod.

- Una métrica de negocio particular de la aplicación (por ejemplo, cantidad de movimientos realizados por el jugador del snake).

Se crea un dashboard en Grafana que contiene estos elementos y se exporta como archivo JSON en `grafana/dashboard.json`, cumpliendo el requerimiento de la consigna.

## Seguridad integrada (DevSecOps)

### 1. Semgrep
Se ejecuta sobre el código de la aplicación Angular, usando el perfil automático. Detecta un hallazgo bloqueante relacionado con USER root en el Dockerfile. Se corrige agregando un usuario no-root explícito (`USER 101`). El reporte queda en `reports/semgrep-report.txt`.

### 2. Snyk
Analiza las dependencias de la aplicación. Cualquier vulnerabilidad crítica provoca que el pipeline falle. El reporte se almacena en `reports/snyk-report.json`.

### 3. Kyverno
Se instalan políticas que incluyen:

- Prohibición de imágenes con tag `latest`.

- Requerimiento de límites de CPU y RAM.

- Obligación de que los contenedores no ejecuten como root.

- Una política adicional de buenas prácticas.

- Los rechazos y validaciones se documentan en `reports/kyverno-validation.log`.

### 4. Falco
Se instala Falco mediante su chart oficial. Se genera un evento sospechoso mediante una acción que no sea abrir un shell dentro del contenedor. Falco registra el evento y se extrae la alerta en `reports/falco-event.log`. El reporte incluye una explicación del incidente detectado.

## Scripts automáticos

### Se incluyen scripts para manejar el ciclo completo del laboratorio:

### `01_up.sh`
Inicializa Minikube, configura el entorno Docker, instala ingress-nginx mediante Helm, construye la imagen, despliega con Helm y levanta Jenkins ya configurado.

### `02_validation.sh`
Ejecuta Trivy sobre la imagen local, genera un reporte de vulnerabilidades y luego ejecuta dive para analizar la composición de capas.

### `03_jenkins.sh`
Levanta un contenedor de Jenkins con todos los plugins necesarios, junto con Semgrep, Snyk, Docker CLI, kubectl y Helm instalados dentro del contenedor.

### `04_populate.sh`
Envía solicitudes a la aplicación para generar tráfico que permita a Prometheus y Grafana capturar métricas útiles.

### `05_down.sh`
Elimina namespace, despliegues, ingress, Prometheus, Grafana, Kyverno, Falco, Jenkins y todos los recursos generados por el laboratorio, asegurando una limpieza completa.

## Problemas encontrados y soluciones implementadas

### a) Jenkins no podía comunicarse con Minikube.
Se utilizó la opción --add-host=minikube:host-gateway y se construyó un kubeconfig específico para Jenkins con rutas corregidas.

### b) El addon de ingress de Minikube dejaba recursos conflictivos.
Se deshabilitó el addon, se limpiaron ClusterRoles antiguos y se instaló ingress-nginx completamente mediante Helm.

### c) Semgrep bloqueaba el pipeline por defecto.
Se corrigió el Dockerfile agregando un usuario no-root para cumplir la regla.

### d) ImagePullBackOff al desplegar.
La imagen se reconstruyó dentro del daemon Docker de Minikube usando `eval "$(minikube docker-env)"`.

### e) Error 429 al intentar instalar Helm desde GitHub.
Se ajustó la instalación para usar `get.helm.sh` en lugar de `raw.githubusercontent.com.`

## Conclusiones y mejoras

Con el trabajo final, el proyecto cumple los objetivos del laboratorio: integración completa de Docker, Kubernetes, Helm, Jenkins, seguridad estática y de dependencias, enforcement de políticas con Kyverno y monitoreo activo con Prometheus/Grafana junto con Falco.

El pipeline es completamente automático, reproducible y detiene la ejecución ante fallas de seguridad, cumpliendo los principios DevSecOps.

Mejoras futuras incluyen agregar pruebas unitarias o end-to-end, publicar la imagen en un registry real, instrumentar métricas más avanzadas y extender la arquitectura hacia un backend real o múltiples servicios.

## Bitácora

1. Empecé a construir al rededor de snakeapp. Creé carpetas para grafana, helm, reports, scripts
2. Hice un script up.sh para levantar el Dockerfile de snakeapp
3. script 02_validation para correr Trivy y Dive contenedorizado
4. Exporté el reporte de trivy y saqué capturas de Dive y los puse en reports. Creé image-analysis.md para completar lo que pide la parte 1 de la consigna
5. Tuve que actualizar alpine, node y angular en el contenedor de snakeapp para corregir vulnerabilidades
6. Cambié la versión de snakeapp a 1.0.1
7. Modifiqué validation para correr sobre 1.0.1