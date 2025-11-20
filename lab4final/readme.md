# Bitácora

1. Empecé a construir al rededor de snakeapp. Creé carpetas para grafana, helm, reports, scripts
2. Hice un script up.sh para levantar el Dockerfile de snakeapp
3. script 02_validation para correr Trivy y Dive contenedorizado
4. Exporté el reporte de trivy y saqué capturas de Dive y los puse en reports. Creé image-analysis.md para completar lo que pide la parte 1 de la consigna
5. Tuve que actualizar alpine, node y angular en el contenedor de snakeapp para corregir vulnerabilidades
6. Cambié la versión de snakeapp a 1.0.1
7. Modifiqué validation para correr sobre 1.0.1