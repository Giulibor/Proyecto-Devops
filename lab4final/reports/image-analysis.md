# Análisis de imagen Docker – Frontend (snake-app)
## Datos básicos

- Imagen analizada: snake-app:1.0.1

- Base image: alpine 3.22.2

- Tamaño total: 53 MB

- Capas totales: 10

- Eficiencia según Dive: 99%

- Potencial espacio desperdiciado: 678 kB

## Vulnerabilidades (Trivy)
### Versión 1.0.0

El análisis de Trivy para snake-app:1.0.0 mostró:

- 19 vulnerabilidades

  - CRITICAL: 2

  - HIGH: 2

  - MEDIUM: 15

Las vulnerabilidades críticas provenían principalmente de:

- libxml2

- curl / libcurl

- openssl (libcrypto3 / libssl3)

Estas CVEs estaban asociadas al uso de Alpine 3.21.3, base que ya no recibía fixes para gran parte de esos paquetes.

### Versión 1.0.1

Luego de actualizar la imagen base a Alpine 3.22.2, reconstruir y limpiar el Dockerfile:

- 0 vulnerabilidades detectadas

Esto demuestra que:

- usar una base image más actual reduce masivamente el riesgo,

- el multi-stage build estaba correctamente aislado y no filtró artefactos vulnerables hacia la imagen final.

## Análisis con Dive
### Cambios detectados entre 1.0.0 y 1.0.1
#### snake-app:1.0.0

- Tamaño total: 48 MB

- Imagen base más vieja: menos librerías, pero vulnerables.

- Eficiencia: 99%

#### snake-app:1.0.1

- Tamaño total: 53 MB (ligeramente mayor por Alpine 3.22 y toolchain)

- Eficiencia: 99%

- Mejora en la estructura y limpieza de capas:

  - No hay node_modules en la imagen final.

  - No quedaron archivos de build.

  - La capa final solo contiene el dist/browser.

### Observaciones de Dive

- La capa dominante es la del runtime de nginx (entre 36–40 MB).

- Las capas RUN intermedias pertenecen al propio nginx-unprivileged.

- La única capa que se agrega es:

  - COPY /app/dist/snake-app/browser /usr/share/nginx/html

- No hay archivos huérfanos ni temporales.

## Decisiones tomadas

### 1. Actualizar Alpine a 3.22.2
   - Eliminó el 100% de las CVEs críticas y altas.

### 2. Mantener multi-stage build
   - Reduce tamaño y elimina dependencias innecesarias.

### 3. Usar nginx-unprivileged
   - Evita correr como root (mejor práctica, menos superficie de ataque).

### 4. Optimización de capas
   - No es necesario modificar más, la eficiencia es del 99%.

## Oportunidades de mejora

### Aunque la imagen quedó en condiciones, se podrían contemplar:

### 1. Congelar digest SHA en la base image
#### Ejemplo:
`FROM nginxinc/nginx-unprivileged:alpine3.22@sha256:<digest>`  Hace build repetible y auditable.

### 2. Implementar CI que bloquee imágenes con vulnerabilidades
Ya teniendo Trivy en pipeline, se puede agregar `--exit-code 1` en stage de análisis.

### 3. Agregar etiquetas OCI estándar

- org.opencontainers.image.source

- org.opencontainers.image.revision

- org.opencontainers.image.created

### 4. Agregar archivo nginx.conf personalizado
En caso de querer implementar cache control, headers extra, entre otros.