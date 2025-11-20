# Análisis de imagen Docker - frontend

## Datos básicos

- Imagen: snake-app:1.0.1
- Tamaño total: 53MB
- Cantidad de capas: 10

## Vulnerabilidades (Trivy/Snyk)

- Herramienta: Trivy
- CRITICAL: <0>
- HIGH: <0>
- MEDIUM: <0>
- LOW: <0>

Decisiones:
- <1> Se actualizó Node/Angular a versión de alpine 3.22 para corregir las CVE 

## Análisis de capas (Dive)

Observaciones:
- Capas con muchos archivos temporales: <detalle>.
- node_modules solo en la capa de build, no en la capa final ✔ / ❌.
- Archivos innecesarios en imagen final: <lista si hay>.

## Mejoras propuestas

- Cambiar base image a <imagen> si aplica.
- Reordenar COPY/RUN para reducir capas.
- Eliminar archivos temporales en la etapa de build.
