# ----- Build stage -----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# build prod (Angular 17/18): genera /dist/snake-app/browser
RUN npm run build

# ----- Runtime stage -----
FROM nginx:alpine
# Nginx por defecto sirve desde /usr/share/nginx/html
COPY --from=build /app/dist/snake-app/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]