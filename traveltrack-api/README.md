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


## Makefile local

Se incluye un Makefile local que permite automatizar el flujo de empaquetado y despliegue.

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
- [x] Push a GHCR (tag inmutable - YYYY.MM.DD.HH.MM)  
- [x] Test con `docker run` y `curl /health`  

### 2. Kubernetes

- [x] Namespace `traveltrack`  
- [x] ConfigMap (`APP_VERSION`, `PORT`)  
- [x] Deployment con imagen GHCR (tag inmutable, sin latest)  
- [x] Service tipo `ClusterIP`  
- [x] Variables de entorno desde ConfigMap  
- [x] requests/limits básicos  
- [x] Probes `/health`  
- [x] Test con `kubectl port-forward` y `curl`  

### 3. Helm

- [x] Estructura `charts/traveltrack-api/`  
- [x] Templates (`deployment.yaml`, `service.yaml`, `configmap.yaml`)  
- [x] `values.yaml` parametrizado  
- [x] Render con `make render`  
- [x] Apply con `make apply`  
- [x] Smoke test con `make smoke`  

### 4. Kyverno (políticas)

- [x] No `:latest`  
- [x] Resources obligatorios  
- [x] runAsNonRoot  
- [x] Test de rechazo  

### 5. Escaneo de Dependencias e Imágenes

- [x] npm audit → Seguridad de dependencias
- [x] Trivy → Vulnerabilidades en la imagen
- [x] SlimToolkit/Dive → Composición y optimización de capas

### 6. KubeLinter

- [x] Validación de manifiestos con KubeLinter
- [x] Generar reporte en `reports/kubelinter.txt`

### 7. Falco (runtime)

- [ ] Instalar Falco en el cluster Minikube
- [ ] Generar una alerta controlada (evento sospechoso)
- [ ] Guardar evidencia en `reports/falco-event.log`

### 8. Documentación

- [ ] README actualizado con roadmap y enlaces a `/reports`
- [ ] Guías en `docs/` alineadas con el alcance del Entregable 3

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