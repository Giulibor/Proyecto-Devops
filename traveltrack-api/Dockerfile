# ---- build stage ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev=false
COPY tsconfig.json .
COPY src ./src
RUN npm run build && npm prune --omit=dev

# ---- runtime stage ----
FROM node:20-alpine
ENV NODE_ENV=production

# Crear usuario/grupo con UID/GID fijo (10001)
RUN addgroup -g 10001 -S appgrp \
 && adduser  -S -D -u 10001 -G appgrp app

WORKDIR /app

# Copiar artefactos del build con ownership correcto
COPY --from=build --chown=10001:10001 /app/node_modules ./node_modules
COPY --from=build --chown=10001:10001 /app/dist         ./dist
COPY --chown=10001:10001 package.json                   ./package.json

# Eliminar npm/npx del runtime para reducir superficie de ataque
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx

# Ejecutar como usuario no-root numérico
USER 10001:10001

EXPOSE 8080
CMD ["node", "dist/server.js"]