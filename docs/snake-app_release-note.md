# RELEASE NOTES

## Version 1.0

Si bien funcionaba en el ambiente de desarrollo, durante la implementacion del mismo en una computadora nueva, no funcionaba el rollout correctamente.

## Version 1.1

### Modificaciones en las instrucciones de ejecución

Se solicita limpieza del ambiente dentro de minikube

```bash
kubectl delete deploy --all
kubectl delete service --all
kubectl delete pods --all
```

### Modificaciones en Dockerfile

Se modificó el Dockerfile, el cual asumía algunas ejecuciones previas a levantar el ambiente en Docker.

```bash
# Añadir node_modules/.bin local al PATH para ejecutar binarios locales como Angular CLI fácilmente
ENV PATH=/app/node_modules/.bin:$PATH
```

```bash
# Instalar todas las dependencias incluyendo devDependencies para permitir la compilación de Angular
# (npm ci con --include=dev asegura que se instalen devDependencies, que son necesarias para las herramientas de construcción)
RUN npm ci --include=dev
```

```bash
# Verificar la versión de Angular CLI y construir la aplicación Angular en modo producción
# Esto genera la salida compilada en /dist/snake-app/browser
RUN ng version && ng build --configuration=production
```

### Archivos nuevos

.docerkignore
