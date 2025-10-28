# TravelTrack API

Microservicio HTTP (Node.js + TypeScript) para gestionar solicitudes de viajes corporativos.

## Endpoints
- `GET /health` → `{ "status": "ok" }`
- `GET /api/version` → `{ "version": "<APP_VERSION>" }`
- `POST /api/travel-requests` → `{ employee, destination, days }` → 201 con objeto creado
- `GET /api/travel-requests` → lista todas
- `PATCH /api/travel-requests/:id/approve` → aprueba una solicitud

## Ejecutar local
```bash
# Requisitos: Node >= 18
npm ci
export APP_VERSION=0.1.0
npm run dev
# curl http://localhost:8080/health
```

## Build y run con Docker
```bash
# Construir imagen con etiqueta explícita
export IMAGE=traveltrack-api:0.1.0
DOCKER_BUILDKIT=1 docker build -t $IMAGE .
# Ejecutar sin root dentro del contenedor (ya configurado en Dockerfile)
docker run --rm -e APP_VERSION=0.1.0 -p 8080:8080 $IMAGE
```

## Lint
```bash
npm run lint
```

## Notas
- Los datos se almacenan **en memoria** (no hay persistencia) tal como indica la consigna.
- La versión se inyecta por `APP_VERSION` (ideal para ConfigMap).
