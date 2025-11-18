# ---------- Build stage ----------
FROM node:20.19.0-alpine3.20 AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---------- Runtime stage ----------
FROM nginx:1.27.2-alpine

# Puerto no privilegiado y config para usuario no-root
# - Cambiamos listen 80 -> 8080
# - Forzamos pid a /tmp/nginx.pid para evitar permisos
RUN sed -ri 's/listen\s+80;/listen 8080;/' /etc/nginx/conf.d/default.conf \
 && (grep -qE '^pid\s+' /etc/nginx/nginx.conf \
      && sed -ri 's#^pid\s+.+;#pid /tmp/nginx.pid;#' /etc/nginx/nginx.conf \
      || echo 'pid /tmp/nginx.pid;' >> /etc/nginx/nginx.conf) \
 && mkdir -p /usr/share/nginx/html /var/cache/nginx /var/run/nginx \
 && chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /run /etc/nginx /etc/nginx/conf.d

# Static files del build Angular
COPY --from=build /app/dist/snake-app/browser /usr/share/nginx/html

# No-root
USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]