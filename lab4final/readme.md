# Laboratorio 4 (DevOps)

### Pasos para configurar Jenkins

#### 1. Desde la carpeta `/scripts`, ejecutar `01_up.sh`

#### 2.  Abrí Jenkins en el navegador
    - `http://localhost:8081`

#### 3. Logueate con el usuario automático
    - Usuario: `admin`
    - Contraseña: `admin123`
#### 4.  Creá el job de tipo Pipeline
    - Menú superior: “Nuevo Tarea” / “New Item”
    - En “Enter an item name”: escribí `lab4-pipeline`

    - En la lista de tipos, seleccioná “Pipeline” (no “Estilo libre / Freestyle”)

    - Botón OK

#### 5.  Configurá el Pipeline con tu repositorio y Jenkinsfile
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

#### 6. Ejecutá el pipeline

    - Entrás al job `lab4-pipeline`.

    - Clic en “Build Now” / “Construir ahora”.

#### 7. Revisá el log del pipeline

    - En la columna izquierda, abajo de “Build History”, clic en el número de build (por ejemplo #1).

    - Clic en “Console Output / Salida de consola”.

    - Verificá que se ejecuten en orden:

        - Checkout del repo

        - Semgrep

        - Snyk

        - Build Angular

        - Build Docker image

        - helm upgrade --install ...
  
#### 8. Ver los reportes de seguridad generados
- Después de ejecutar el pipeline y/o 01_up.sh:
  - `reports/semgrep-report.txt` → Reporte de análisis estático Semgrep.
  - `reports/snyk-report.json` → Vulnerabilidades de dependencias.
  - `reports/kyverno-validation.log` → Validación de políticas Kyverno sobre los pods.
  - `reports/falco-event.log` → Eventos detectados por Falco.

## Descripción general del proyecto

El proyecto consiste en implementar un flujo completo de integración continua, entrega continua y seguridad integrada (DevSecOps) para una aplicación Angular llamada snake-app. Se utilizan contenedores Docker, un cluster Kubernetes desplegado con Minikube, plantillas Helm para gestionar el despliegue, Jenkins como herramienta principal de CI/CD y un conjunto de herramientas de seguridad y monitoreo: Semgrep, Snyk, Kyverno, Falco, Prometheus y Grafana.

El objetivo es que cada cambio en el repositorio active un pipeline que analice el código, valide dependencias, construya la aplicación, genere una imagen Docker válida, la despliegue en Kubernetes y quede monitoreada por Prometheus y Grafana, mientras Kyverno aplica políticas de seguridad y Falco detecta eventos maliciosos en tiempo de ejecución.

## Arquitectura final del sistema

[![](https://mermaid.ink/img/pako:eNqNVF1v2kgU_SujkbqiUiBAPiBoVcnYhhCwQbib3dZU1dgeYMp4xp2PdNM0P6aPfejT_gT-2M7YNAlFkTIvHtvn3HvumXvnDqY8w7AHl5R_SddIKDCZL9iCAbOkTlYCFWswmbrO5HIavY0XMNh-_6wJQ4DyFFGQYQqwVDojiCm8gB8q6h79yg_HozAy5CvMNoRJUHNHx673eg9u19Ug3kGWhOI_E3H8JsL5SuCi2rPbTbnxeLrBAiSa0Kz8cIlpbrQUlN8-CYlZ9qsWu_rz6d-RP4_7gn-Rhm61a6mRIHxHekJ4UB-MwtH4r75v5LtUS2WIAWFko5Nnyh2Fw7kf2XJHzEiXsh4OR-E_B8XOW3FtjlcUSaME7LBlNZKhDUZF0Sg9VsbfRo5fP1_YQ-rQCfxo5rj-x4nTPzUKQpRjWaAUA4qS0wMJnj-bTN_FsVc6l2OmHvPXjYAPv-GjazeuRVjckHRPj11uENdczpZkFaDiJWLH7679eTg1Kse3N1gwDmrXiJIMpWT7HztsjvFsOolnnG5_KpKiyinGWV1wrnYvdYqsW-WbcZNrkeIKWAieYPkCVQNn4lpNA0RTo8jDCqcKAeMjQ1-RPJQ18Bw_mIZxzUM45yzCVfql5b_EhuHcGTihY1IOBVoiM1m1aWLa8wYlxLqRHaYcek50aRPKdcKRyKoSg-0PJawzz2R9sn31Cgyo_sRt45WjWH2-GoB6_c23vh0r8AeYabkGxIy1OZtvu17ZA5ZTpwtTR4aPzdAqROkj8CHVW7H9viRpmW03b9W_3UDaWGYayofpsPJ5EORXa3CGJTgGEV5pYd2pABW8ZNo2Ofi4O6Qn8fY9BkuttEAHvNJpeARXJhfsmTOV-AjmWOTIvsM7S1hAtca5uQx6ZpshsVnABbs3pAKx95znsKeENjTB9Wr9EEQXmelVjyDj3iPEnBEWLtdMwV67e1HGgL07-C_snXUb3Wanc37R6ZydXDTP22dH8Bb2LpoNA-x2Wu3WWbfdPGndH8GvZdZmo9ttNk_bJ6ftZuu8e27D4YwoLoLqzi-v_vv_ARN_0zs?type=png)](https://mermaid.live/edit#pako:eNqNVF1v2kgU_SujkbqiUiBAPiBoVcnYhhCwQbib3dZU1dgeYMp4xp2PdNM0P6aPfejT_gT-2M7YNAlFkTIvHtvn3HvumXvnDqY8w7AHl5R_SddIKDCZL9iCAbOkTlYCFWswmbrO5HIavY0XMNh-_6wJQ4DyFFGQYQqwVDojiCm8gB8q6h79yg_HozAy5CvMNoRJUHNHx673eg9u19Ug3kGWhOI_E3H8JsL5SuCi2rPbTbnxeLrBAiSa0Kz8cIlpbrQUlN8-CYlZ9qsWu_rz6d-RP4_7gn-Rhm61a6mRIHxHekJ4UB-MwtH4r75v5LtUS2WIAWFko5Nnyh2Fw7kf2XJHzEiXsh4OR-E_B8XOW3FtjlcUSaME7LBlNZKhDUZF0Sg9VsbfRo5fP1_YQ-rQCfxo5rj-x4nTPzUKQpRjWaAUA4qS0wMJnj-bTN_FsVc6l2OmHvPXjYAPv-GjazeuRVjckHRPj11uENdczpZkFaDiJWLH7679eTg1Kse3N1gwDmrXiJIMpWT7HztsjvFsOolnnG5_KpKiyinGWV1wrnYvdYqsW-WbcZNrkeIKWAieYPkCVQNn4lpNA0RTo8jDCqcKAeMjQ1-RPJQ18Bw_mIZxzUM45yzCVfql5b_EhuHcGTihY1IOBVoiM1m1aWLa8wYlxLqRHaYcek50aRPKdcKRyKoSg-0PJawzz2R9sn31Cgyo_sRt45WjWH2-GoB6_c23vh0r8AeYabkGxIy1OZtvu17ZA5ZTpwtTR4aPzdAqROkj8CHVW7H9viRpmW03b9W_3UDaWGYayofpsPJ5EORXa3CGJTgGEV5pYd2pABW8ZNo2Ofi4O6Qn8fY9BkuttEAHvNJpeARXJhfsmTOV-AjmWOTIvsM7S1hAtca5uQx6ZpshsVnABbs3pAKx95znsKeENjTB9Wr9EEQXmelVjyDj3iPEnBEWLtdMwV67e1HGgL07-C_snXUb3Wanc37R6ZydXDTP22dH8Bb2LpoNA-x2Wu3WWbfdPGndH8GvZdZmo9ttNk_bJ6ftZuu8e27D4YwoLoLqzi-v_vv_ARN_0zs)

### La arquitectura incluye:

La arquitectura final está compuesta por un clúster de Kubernetes ejecutándose en Minikube, donde se despliega la aplicación frontend “snake-app” empaquetada como imagen Docker. La entrega continua se ejecuta en Jenkins, montado como contenedor independiente, con un pipeline que valida código, analiza vulnerabilidades, construye la imagen y actualiza el despliegue mediante Helm. La seguridad del cluster está reforzada con Kyverno para validación de políticas y Falco para monitoreo de comportamiento a nivel de nodo. El acceso HTTP hacia la aplicación se gestiona mediante ingress-nginx. La construcción de imágenes se delega al daemon Docker interno de Minikube para evitar problemas de ImagePull.

### La arquitectura se organiza de la siguiente forma:

#### 1. Jenkins (fuera del cluster)
- Ejecutado como contenedor Docker.
- Conducto de CI/CD encargado de:
   - Semgrep (análisis estático).
   - Snyk (vulnerabilidades en dependencias).
   - Build Angular + build Docker.
   - Push de imagen local al daemon de Minikube.
   - helm upgrade para desplegar al clúster.
- Utiliza un kubeconfig personalizado para comunicarse con el cluster.

#### 2. Minikube
- Clúster local con un único nodo.
- Docker daemon interno utilizado para construir la imagen consumida por Kubernetes.
- Addon de ingress deshabilitado para evitar conflictos con ingress-nginx instalado vía Helm.

#### 3. ingress-nginx
- Instalado vía Helm para manejar Routing HTTP.
- Expone snake-app mediante reglas definidas en el Chart.

#### 4. Helm
- Encargado de empaquetar y desplegar la aplicación snake-app con parámetros configurables.
- Define Deployment, Service, Ingress y ConfigMaps.
- Permite promover nuevos builds desde Jenkins mediante la variable image.tag.

#### 5. Kyverno
- Instalado vía Helm.
- Aplica políticas de seguridad:
  - Prohibición de usar tag latest.
  - Requerimiento de requests/limits.
  - Prohibición de ejecutar como root.
  - Probes obligatorias.
- Genera PolicyReports consumidos como evidencia en el entregable.

#### 6. Falco
- Instalado vía Helm como DaemonSet.
- Monitorea syscalls del nodo y genera alertas ante ejecución sospechosa o comportamiento no permitido.
- Evidencias registradas en logs del pod falco.

#### 7. Aplicación snake-app
- Imagen generada en dos etapas: build con Angular y runtime sobre nginx-unprivileged.
- Corre como usuario no root (USER 101).
- Se expone mediante Service ClusterIP y una regla de Ingress.

#### 8. Grafana

Grafana se integra con las métricas expuestas por Prometheus y permite construir dashboards para:

- uso de CPU/Memoria por Deployment

- comportamiento de réplicas

- estado del Ingress

- métricas de red del nodo de Minikube

- evolución de pods en el namespace lab4

La inclusión del componente en la arquitectura responde al requisito de demostrar una solución extensible hacia monitoreo completo de aplicaciones en Kubernetes.

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

Para el análisis estático del código se utilizó Semgrep ejecutado desde el pipeline de Jenkins, en la etapa “Semgrep”, con el siguiente comando:

`semgrep --config auto lab4final/front/snakeapp --output reports/semgrep-report.txt --error`

La opción `--config auto` permite aplicar un conjunto de reglas por defecto en función de los lenguajes detectados (TypeScript, HTML, Dockerfile, etc.), y la opción `--error` hace que cualquier hallazgo de severidad bloqueante provoque que el comando devuelva un código de salida distinto de cero, deteniendo el pipeline.

En la primera ejecución del laboratorio, Semgrep reportó un hallazgo bloqueante en el Dockerfile de la aplicación (regla `dockerfile.security.missing-user.missing-user`), indicando que no se estaba especificando un usuario no-root al final del Dockerfile. Esto implicaba que el proceso podía ejecutarse como root dentro del contenedor, lo cual representa un riesgo de seguridad. La corrección aplicada consistió en modificar la etapa final del Dockerfile para establecer explícitamente un usuario no-root (`USER 101`), manteniendo la imagen basada en nginx-unprivileged.

Luego de aplicar esta corrección, se re-ejecutó el pipeline y Semgrep ya no reportó findings bloqueantes: el resumen indica “`Findings: 0 (0 blocking)`”. El reporte completo del análisis se encuentra almacenado en el archivo `reports/semgrep-report.txt`, que forma parte de los artefactos archivados por Jenkins al finalizar la ejecución del pipeline.

Con esto se cumple el requisito de la consigna de integrar un análisis estático en el pipeline y de detener la ejecución ante problemas de seguridad relevantes, además de documentar el hallazgo y la corrección aplicada.

### 2. Snyk

Para el escaneo de vulnerabilidades en las dependencias se utilizó Snyk, también integrado en el pipeline de Jenkins en la etapa “Snyk - dependencias”. En esa etapa se ejecuta:

`snyk test --file=package.json --severity-threshold=critical --json > ../../reports/snyk-report.json`

El análisis se realiza sobre el archivo package.json del proyecto snake-app (packageManager: npm), con un umbral de severidad configurado en critical. Esto significa que solo las vulnerabilidades críticas provocan fallo del comando y, por lo tanto, detienen el pipeline. El resultado del comando se guarda en `reports/snyk-report.json` y Jenkins archiva este archivo como artefacto de la ejecución.

El reporte JSON obtenido muestra, entre otros campos, lo siguiente:
```
ok: true

vulnerabilities: []

summary: "No critical severity vulnerabilities"

dependencyCount: 20

projectName: "snake-app"

displayTargetFile: "package.json"

severityThreshold: "critical"
```
Estos valores indican que Snyk analizó 20 dependencias del proyecto y no encontró vulnerabilidades con severidad crítica, por lo que la etapa de Snyk se considera exitosa y el pipeline continúa con las siguientes fases. Además, el reporte incluye la política de licencias asociada a la organización (licensesPolicy/orgLicenseRules), aunque en este proyecto concreto no se han detectado conflictos de licencias que afecten al resultado.

### 3. Kyverno

#### Se desplegaron cuatro políticas de validación orientadas a buenas prácticas de seguridad:

1. disallow-latest-tag: evita que se usen imágenes con tag latest.
2. require-probes: exige livenessProbe y readinessProbe.
3. require-resources: obliga a definir requests y limits de CPU y memoria.
4. require-run-as-non-root: impide ejecutar contenedores como root.

Una vez aplicadas las políticas, Kyverno generó automáticamente PolicyReports para todos los recursos del namespace lab4 (Deployment, ReplicaSet y Pods).

En todos los casos se observa lo siguiente en `kyverno-validation.log`:

```
summary:
  error: 0
  fail: 0
  pass: 4
  skip: 0
  warn: 0

results:
  - message: validation rule 'disallow-latest-tag' passed.
  - message: validation rule 'require-container-resources' passed.
  - message: validation rule 'require-run-as-non-root' passed.
  - message: validation rule 'require-liveness-readiness' passed.

```

- 0 errores
- 0 fallas
- 4 reglas “pass”
- Las reglas autogen confirman que Kyverno generó validaciones para Pods creados por el Deployment.
- Los reportes muestran que el Deployment y los Pods cumplen todos los requisitos de las políticas instaladas.

### 4. Falco
Se instala Falco mediante su chart oficial. Falco registra los eventos sospechosos y se extraen las alerta en `reports/falco-event.log`. El reporte incluye una explicación de los incidentes detectado.

## Scripts automáticos

### Se incluyen scripts para manejar el ciclo completo del laboratorio:

### `01_up.sh`
Inicializa Minikube, configura el entorno Docker, instala ingress-nginx mediante Helm, construye la imagen, despliega con Helm y levanta Jenkins ya configurado.

### `02_validation.sh`
Ejecuta Trivy sobre la imagen local, genera un reporte de vulnerabilidades y luego ejecuta dive para analizar la composición de capas.

### `03_jenkins.sh`
Levanta un contenedor de Jenkins con todos los plugins necesarios, junto con Semgrep, Snyk, Docker CLI, kubectl y Helm instalados dentro del contenedor.

### `04_kyverno.sh`
Realiza el Deploy de Kyverno y sus policies.

### `05_falco.sh`
Levanta Falco.

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

### f) Kyverno no aplicaba políticas por versiones deprecated de enforcement.

Se actualizaron las políticas para usar Enforce en lugar de enforce, evitando warnings e inconsistencias al crear ClusterPolicyReport.

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