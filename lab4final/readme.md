# Bitácora

1. Empecé a construir al rededor de snakeapp. Creé carpetas para grafana, helm, reports, scripts
2. Hice un script up.sh para levantar el Dockerfile de snakeapp
3. script 02_validation para correr Trivy y Dive contenedorizado
4. Exporté el reporte de trivy y saqué capturas de Dive y los puse en reports. Creé image-analysis.md para completar lo que pide la parte 1 de la consigna
5. Tuve que actualizar alpine, node y angular en el contenedor de snakeapp para corregir vulnerabilidades
6. Cambié la versión de snakeapp a 1.0.1
7. Modifiqué validation para correr sobre 1.0.1

# Pasos

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