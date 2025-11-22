# Análisis de imagen - traveltrack-api

- **Imagen analizada**: `ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58`
- **Tamaño reportado** (`docker image ls`): ~140 MB
- **Capas** (`docker history <image-name:version>`): 19 capas visibles

## Observaciones

- La imagen usa base `<imagen base>` (por ejemplo, `eclipse-temurin:21-jre-alpine`).
- Se observan capas relacionadas a instalación de dependencias / build tool (Gradle, etc.).
- Podrían optimizarse:
  - Consolidando pasos del Dockerfile (RUN) para reducir capas.
  - Revisando si hay herramientas de build que podrían quedarse fuera de la imagen final (multi-stage más agresivo).
- Para efectos del lab, se mantiene el Dockerfile actual y se registra sólo el análisis.

## Evidencias

- Comando ejecutado:

  ```bash
  slim xray --target ghcr.io/<GH_USER>/traveltrack-api:<IMAGE_VERSION> \
    --report reports/slim-xray.report.json