# Image Analysis – snake-frontend:1.0.0

## Resumen
- **Imagen base (runtime):** nginx:1.27.2-alpine
- **Usuario en runtime:** nginx 
- **Puerto expuesto:** 8080
- **Multi-stage build:** Sí 

## Tamaño total
- **Tamaño reportado por `docker images`:** 85.9 MB
Este tamaño corresponde a la suma de todas las capas de la imagen nginx:alpine más la configuración aplicada y los artefactos estáticos generados por Angular.

## Capas
- **Cantidad de capas (runtime):** 
Según docker history, la imagen tiene ~20 capas heredadas de: 
  - Alpine base
  - Build de Nginx
  - Scripts del entrypoint
  - Configuración de nginx
  - Parche (puerto 8080 + permisos)
  - COPY dist (artefactos de Angular)

Dive reportó:
  - Tamaño efectivo: ~57 MB
  - Sin “wasted space” significativo

- **Capas más pesadas:** 
  - Base nginx (~40 MB): Incluye bibliotecas del sistema y componentes como OpenSSL.
  - Paquetes internos del runtime Alpine/Nginx: ~11.6 MB
  - Rootfs Alpine: ~9.49 MB
  - Parche de configuración + permisos: ~94 KB
  - Assets Angular (COPY dist): ~295 KB

## Vulnerabilidades
- **Herramienta:** Trivy v0.67
- **OS detectafo:** Alpine 3.20.3
- **Paquetes analizados:** 66
- **Severidades encontrados:**
(Del análisis general — los detalles están en trivy-frontend-1.0.0.json)
- CRITICAL: 1
- HIGH: varias (bibliotecas base de Alpine como OpenSSL, libexpat, libxslt)
- MEDIUM / LOW: pueden aparecer dependiendo del snapshot de repositorio

- **Observaciones:**
  - Las vulnerabilidades provienen exclusivamente de Alpine + Nginx, no de tu código.
  - Los archivos estáticos de Angular no contienen paquetes ejecutables ni dependencias.

## Oportunidades de optimización
Ya aplicadas
  - Multi-stage build (minimiza tamaño final)
  - Solo se copian los archivos necesarios del dist/.../browser
  - Usuario no root (USER nginx)
  - Puerto no privilegiado (8080)

## Comandos ejecutados (bitácora)
**Construit imagen** /p
docker build -t snake-frontend:1.0.0 . 
docker run --rm -p 8080:8080 snake-frontend:1.0.0 0 - probar la imagen localmente

docker images snake-frontend:1.0.0 - ver información de la imagen
docker history snake-frontend:1.0.0 - ver detalle de capas

trivy image --severity HIGH,CRITICAL --format table snake-frontend:1.0.0 - Scan de vulnerabilidades con Trivy (resumen en consola)
trivy image --format json -o reports/trivy-frontend-1.0.0.json snake-frontend:1.0.0 - Scan de vulnerabilidades con salida en JSON

dive snake-frontend:1.0.0 - Análisis de capas y espacio con Dive
