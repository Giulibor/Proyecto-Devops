# TravelTrack API

Microservicio HTTP (Node.js + TypeScript) para gestionar solicitudes de viajes corporativos.

---

## Endpoints

- `GET /health` → `{ "status": "ok" }`
- `GET /api/version` → `{ "version": "<APP_VERSION>" }`
- `POST /api/travel-requests` → `{ employee, destination, days }` → 201 con objeto creado
- `GET /api/travel-requests` → lista todas
- `PATCH /api/travel-requests/:id/approve` → aprueba una solicitud

## Almacenamiento de datos

- Los datos se almacenan **en memoria** (no hay persistencia).


## Ejecutar local

```bash
# Requisitos: Node >= 18
npm ci
export APP_VERSION=0.1.0
npm run dev
# curl http://localhost:8080/health
```

- La versión se inyecta por `APP_VERSION` (ideal para ConfigMap).

## Build y run con Docker

```bash
# Construir imagen con etiqueta explícita
export IMAGE=traveltrack-api:2025.11.09.00.00
DOCKER_BUILDKIT=1 docker build -t $IMAGE .
# Ejecutar sin root dentro del contenedor (ya configurado en Dockerfile)
docker run --rm -e APP_VERSION=0.1.0 -p 8080:8080 $IMAGE
```

## Uso de Helm

Helm se utiliza para generar un manifiesto YAML (`/deploy/tt.yaml`) que se aplica en Kubernetes para desplegar la aplicación de forma sencilla y reproducible.

## Makefile local

Se incluye un Makefile local que permite automatizar el flujo de empaquetado y despliegue sin necesidad de instalar Helm directamente. Los comandos principales son:

- `make render`: genera el manifiesto YAML a partir de las plantillas.
- `make apply`: aplica el manifiesto generado en el clúster Kubernetes.
- `make smoke`: ejecuta pruebas básicas para verificar el despliegue.
- `make clean`: elimina recursos y limpia el entorno.

Este flujo facilita la gestión del ciclo de vida de la aplicación de manera rápida y sencilla.

---

## Roadmap & Estado

### 0. Fundaciones (MVP)

- [x] API Node+TS (health, version, travel-requests)
- [x] ESM prod-ready (imports .js, NodeNext)
- [x] Dockerfile sin root
- [x] Smoke local (curl)

### 1. Empaquetado

- [x] Build local `traveltrack-api:0.1.0`
- [x] Multi-arch (buildx)
- [x] Push a registry (tag inmutable - YYYY.MM.DD.HH.MM)

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

## Estrategia de ramas (branch strategy)

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
    ```

2. Desarrollar y testear localmente (o en minikube).
3. Crear Pull Request hacia `laboratorio3` para revisión.
4. Cuando el conjunto de features esté maduro, mergear `laboratorio3 → pre-release`.
5. Finalmente, tras validación general, mergear `pre-release → main`.

### Objetivo

Mantener un flujo ordenado que permita:

- Revisiones intermedias por etapa.
- Entregas parciales sin afectar la rama estable.
- Integración progresiva de los laboratorios en el repositorio central.

Perfecto — acá tenés un diagrama ASCII simple y limpio, ideal para el README (sin necesidad de renderizado adicional):

---

### Diagrama de flujo de ramas

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


---

## Estructura y documentación del proyecto

El repositorio está organizado para mantener el código fuente, la infraestructura y la documentación de manera modular y reproducible:

```
traveltrack-api/
├── src/                       # Código fuente (Node.js + TypeScript)
│   ├── routes/                # Rutas y lógica
│   │   └── travelRequests.ts  # Endpoints para solicitudes de viaje
│   ├── config.ts              # Configuración y constantes
│   ├── server.ts              # Inicialización del servidor Express
│   ├── store.ts               # Almacenamiento en memoria
│   └── types.ts               # Tipos y definiciones TypeScript
│
├── charts/                    # Helm Chart (plantillas para despliegue en K8s)
├── deploy/                    # Manifiestos YAML generados automáticamente
├── docs/                      # Documentación técnica y guías operativas
│   ├── deploy-traveltrack.md  # Guía de despliegue principal (macOS/Linux)
│   ├── deploy-traveltracker-from-windows-wsl2.md # Guía de despliegue desde Windows / WSL2
│   ├── publish-to-ghcr.md     # Guía de publicación en GHCR
│   └── Makefile referencias y notas de uso
│
├── Makefile                 # Automatización principal (build, deploy, GHCR)
├── Makefile.windows         # Adaptación para entornos Windows/WSL2
├── .env.example             # Variables de entorno de referencia
├── Dockerfile               # Imagen base (multi-arch, sin root)
└── README.md                # Este archivo
```

### Guías de despliegue

Para realizar el despliegue completo de la aplicación:

- En **macOS / Linux**: seguir `docs/deploy-traveltrack.md`  
- En **Windows / WSL2**: seguir `docs/deploy-traveltracker-from-windows-wsl2.md`

Cada guía detalla el flujo completo:
- Preparación del entorno  
- Construcción y publicación multi-arquitectura  
- Despliegue desde GHCR  
- Pruebas (smoke test)  
- Limpieza del entorno