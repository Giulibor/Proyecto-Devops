# Dockerfile multi-etapa para construir y servir una aplicación Angular.
# 
# Este Dockerfile utiliza un proceso de construcción en dos etapas:
# 1. Etapa de construcción: Usa un entorno Node.js para instalar dependencias y construir la aplicación Angular.
# 2. Etapa de ejecución: Usa un servidor Nginx para servir los archivos estáticos compilados.
#

# ----- Etapa de construcción -----
FROM node:20-alpine AS build
WORKDIR /app

# Añadir node_modules/.bin local al PATH para ejecutar binarios locales como Angular CLI fácilmente
ENV PATH=/app/node_modules/.bin:$PATH

# Copiar package.json y package-lock.json primero para aprovechar la caché de Docker en npm install
COPY package*.json ./

# Instalar todas las dependencias incluyendo devDependencies para permitir la compilación de Angular
# (npm ci con --include=dev asegura que se instalen devDependencies, que son necesarias para las herramientas de construcción)
RUN npm ci --include=dev

# Copiar el resto del código fuente de la aplicación después de instalar dependencias
COPY . .

# Verificar la versión de Angular CLI y construir la aplicación Angular en modo producción
# Esto genera la salida compilada en /dist/snake-app/browser
RUN ng version && ng build --configuration=production

# ----- Etapa de ejecución -----
FROM nginx:alpine

# Copiar la aplicación Angular compilada desde la etapa de construcción al directorio html por defecto de Nginx
# Nginx servirá los archivos estáticos desde /usr/share/nginx/html
COPY --from=build /app/dist/snake-app/browser /usr/share/nginx/html

# Exponer el puerto 80 para permitir tráfico HTTP entrante
EXPOSE 80

# Iniciar Nginx en primer plano para que el contenedor siga en ejecución
CMD ["nginx", "-g", "daemon off;"]