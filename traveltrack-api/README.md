# TravelTrack API

Microservicio HTTP (Node.js + TypeScript) para gestionar solicitudes de viajes corporativos.

---

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

---

## 🗺️ Roadmap & Estado

### 0. Fundaciones (MVP)

- [x] API Node+TS (health, version, travel-requests)
- [x] ESM prod-ready (imports .js, NodeNext)
- [x] Dockerfile sin root
- [x] Smoke local (curl)

### 1. Empaquetado

- [x] Build local `traveltrack-api:0.1.0`
- [ ] Multi-arch (buildx)
- [ ] Push a registry (tag inmutable)

### 2. Config externa (K8s)

- [ ] ConfigMap (APP_VERSION/PORT)
- [ ] values.yaml comentado

### 3. Helm / K8s

- [ ] Deployment + Service + ConfigMap
- [ ] requests/limits
- [ ] imagen con tag (no latest)

### 4. Kyverno (políticas)

- [ ] no `:latest`
- [ ] resources obligatorios
- [ ] runAsNonRoot
- [ ] test de rechazo

### 5. Escaneos /reports

- [ ] npm audit → `reports/npm-audit.txt`
- [ ] Trivy → `reports/trivy-report.txt`
- [ ] SlimToolkit/Dive → `reports/image-analysis.md`

### 6. KubeLinter

- [ ] `reports/kubelinter.txt`

### 7. Falco (runtime)

- [ ] instalar y generar alerta → `reports/falco-event.log`

### 8. CI (GitHub Actions)

- [ ] build & push imagen
- [ ] audit + Trivy (artifacts/fail)

### 9. Documentación

- [ ] README con pasos y links a `/reports`

> **Criterios de aceptación**: cada ítem indica evidencia (comando, reporte o manifest) para reproducibilidad.

---

## 🌿 Estrategia de ramas (branch strategy)

Este laboratorio utiliza una estrategia de ramas jerárquica para mantener un flujo de integración controlado y reproducible.

### Estructura general

main ← pre-release ← laboratorio3 ← feature/laboratorio3-xx-*

### Descripción

| Rama | Propósito | Permisos / Uso |
|-------|------------|----------------|
| **main** | Producción estable. Contiene solo entregas validadas y documentadas. | Merge desde `pre-release` una vez validado el laboratorio completo. |
| **pre-release** | Etapa previa a `main`. Integra todos los laboratorios y pruebas completas del equipo. | Merge desde `laboratorio3` cuando el avance está probado y estable. |
| **laboratorio3** | Rama base específica del **Laboratorio 3**. Es el entorno de desarrollo principal para esta entrega. | Se crean ramas de trabajo individuales desde aquí. |
| **laboratorio3-xx-nombre** | Ramas de desarrollo específicas (por ejemplo `laboratorio3-01-fundaciones`, `laboratorio3-02-helm`). Cada una aborda una parte del laboratorio. | Se mergean a `laboratorio3` mediante pull requests con revisión. |

### Flujo recomendado

1. Crear una nueva rama desde `laboratorio3`:

    ```bash
    git checkout laboratorio3
    git pull
    git checkout -b laboratorio3-01-fundaciones
    ````

2. Desarrollar y testear localmente (o en minikube).
3. Crear Pull Request hacia `laboratorio3` para revisión.
4. Cuando el conjunto de features esté maduro, mergear `laboratorio3 → pre-release`.
5. Finalmente, tras validación general, mergear `pre-release → main`.

### Objetivo

Mantener un flujo ordenado que permita:

- Revisiones intermedias por etapa.
- Entregas parciales sin afectar la rama estable.
- Integración progresiva de los laboratorios en el repositorio central.

Perfecto 💪 — acá tenés un diagrama ASCII simple y limpio, ideal para el README (sin necesidad de renderizado adicional):

---

### 🧩 Diagrama de flujo de ramas

```
     ┌────────────┐
     │   main     │
     └─────▲──────┘
           │
    merge (release estable)
           │
     ┌─────┴──────┐
     │ pre-release│
     └─────▲──────┘
           │
   merge (laboratorio validado)
           │
     ┌─────┴────────┐
     │ laboratorio3 │  ← base del laboratorio
     └─────▲────────┘
           │
  ┌────────┴────────┐
  │                 │
┌────────────┐   ┌────────────┐
│ lab3-01-...│   │ lab3-02-...│  ← desarrollo por módulos
└────────────┘   └────────────┘

```
