

# Análisis de Imagen – Dive

## Imagen Analizada
- **Nombre:** `ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58`
- **Tamaño total:** ~140 MB
- **Puntaje de eficiencia reportado:** 99 %
- **Espacio potencialmente desperdiciado:** 87 KB

## Resumen General
El análisis realizado con Dive muestra que la imagen contiene únicamente los artefactos necesarios para ejecutar la aplicación Node.js. Gracias al uso de build multi-stage y la eliminación explícita de herramientas como `npm`/`npx` en la etapa final, el runtime queda limpio y con una huella mínima.

No se observan archivos innecesarios, toolchains de build, carpetas de caché ni duplicados grandes. La estructura es estable y optimizada.

## Capas Principales
A continuación se resumen las capas más relevantes observadas en el panel de Dive:

| Nº | Tamaño | Comando (Dockerfile) | Comentario |
|----|--------|-----------------------|------------|
| 1 | 8.5 MB | `FROM ...` | Imagen base minimalista. |
| 2 | 12.8 MB | `RUN addgroup/adduser ...` | Creación de usuario no root (UID/GID 10001). |
| 3 | 3.8 MB | `COPY docker-entrypoint.sh` | Script de arranque. |
| 4 | 5.3 MB | `RUN ... apk add ...` | Instalación de dependencias de runtime. |
| 5 | 6.1 MB | `COPY --chown=10001 node_modules` | Dependencias de producción. |
| 6 | 5.3 MB | `COPY dist/` | Código compilado final. |
| 7 | 0 B | `RUN rm -rf /usr/local/lib/node_modules/npm` | Eliminación de npm/npx. |

Las capas son consistentes y no muestran signos de archivos sobrantes.

## Usuario y Permisos
Todos los archivos relevantes aparecen con:
- **UID:** 10001
- **GID:** 10001

Lo cual confirma que el contenedor cumple la política `runAsNonRoot`.

## Archivos Presentes en la Imagen
Dive muestra principalmente:
- Librerías Node de producción en `/usr/local/lib/node_modules`.
- Archivos de configuración mínimos en `/etc/`.
- Archivos del paquete (`dist/`).

No se observan:
- Carpeta `.git/`
- Caches de build
- Dependencias dev
- Toolchains

## Comandos Ejecutados para el Análisis
```
docker pull ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58

docker run --rm -it \ 
  -v /var/run/docker.sock:/var/run/docker.sock \ 
  wagoodman/dive:latest \ 
  ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58
```

## Conclusión
La imagen está correctamente optimizada. Su tamaño, estructura de capas y nivel de eficiencia indican un uso adecuado de multi-stage builds y buenas prácticas para contenedores productivos.