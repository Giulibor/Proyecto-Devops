# ---------- Build stage ----------
FROM node:20.19.0-alpine3.20 AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---------- Runtime stage ----------
FROM node:20.19.0-alpine AS runtime
WORKDIR /app

# Copy only what we need from build stage
COPY --from=build /app/dist/snake-app/browser /app/dist/snake-app/browser
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy server code (we will add server/index.js in the repo)
COPY server ./server

ENV PORT=8080
EXPOSE 8080
CMD ["node", "server/index.js"]