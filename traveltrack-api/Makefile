# ===========================
# TravelTrack API - Makefile
# ===========================
# Este Makefile se ejecuta desde dentro de traveltrack-api/
# Ejemplo de uso:
#   make start-minikube
#   make build-in-minikube
#   make render
#   make apply
#   make smoke
#   make uninstall

SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help
help: ## Muestra esta ayuda con la lista de comandos disponibles
	@echo "make <target>"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

# -------- Variables --------
IMAGE_VERSION ?= $(shell date +"%Y.%m.%d.%H.%M")
APP_VERSION   ?= 1.0.0

ifeq ($(IMAGE_VERSION),auto)
IMAGE_VERSION := $(shell date +"%Y.%m.%d.%H.%M")
endif

IMAGE         ?= traveltrack-api
NAMESPACE     ?= traveltrack
RELEASE       ?= tt

CHART_DIR     := charts/traveltrack-api
DEPLOY_DIR    := deploy
RENDER_FILE   := $(DEPLOY_DIR)/tt.yaml
VALUES_FILE   := $(CHART_DIR)/values.yaml

HELM_IMG      ?= alpine/helm:3.15.3

# -------- Buildx / Multi-arch --------
PLATFORMS     ?= linux/amd64,linux/arm64
# Multi-arch por defecto (true|false)
MULTIARCH    ?= true

# -------- GHCR (GitHub Container Registry) --------
GH_USER       ?= 
GHCR_REG      ?= ghcr.io
GHCR_IMAGE    := $(GHCR_REG)/$(GH_USER)/$(IMAGE)

.PHONY: _ensure-dirs
_ensure-dirs:
	@mkdir -p $(DEPLOY_DIR)
	@if [ ! -d "$(CHART_DIR)" ]; then \
	  echo "[ERROR] No se encuentra el chart en $(CHART_DIR)"; \
	  exit 1; \
	fi

# -------- Minikube --------
.PHONY: start-minikube stop-minikube status
start-minikube: ## Inicia minikube
	minikube start --driver=docker --memory=4096 --cpus=2

stop-minikube: ## Detiene minikube
	minikube stop

status: ## Muestra estado de minikube y nodos
	minikube status
	kubectl get nodes

# -------- Alternar Docker daemon --------
.PHONY: use-minikube-docker use-host-docker which-docker doctor
use-minikube-docker: ## Cambia Docker CLI al daemon de Minikube
	@eval "$$(minikube docker-env)"; \
	echo "[OK] Docker CLI apuntando al daemon de Minikube."; \
	docker info | grep -i 'name' || true

use-host-docker: ## Restaura Docker CLI del host
	@eval "$$(minikube docker-env -u)"; \
	echo "[OK] Docker CLI de tu host restaurado."; \
	docker info | grep -i 'name' || true

which-docker: ## Indica a qué daemon Docker apunta la CLI
	@echo "DOCKER_HOST=$$DOCKER_HOST"
	@docker info | grep -i 'name' || true

doctor: ## Diagnóstico rápido del entorno (Docker, Minikube, kubectl, buildx)
	@echo "=== DOCTOR ==="
	@echo "[OS] uname -s: $$(uname -s)"
	@echo "[Docker] version:"; docker version --format '{{.Server.Version}}' 2>/dev/null || echo "no disponible"
	@echo "[Docker] daemon name:"; docker info 2>/dev/null | grep -i '^ name' || echo "no disponible"
	@echo "[kubectl] client:"; kubectl version --client --short 2>/dev/null || echo "no disponible"
	@echo "[minikube] version:"; minikube version 2>/dev/null || echo "no disponible"
	@echo "[buildx] info:"; docker buildx version 2>/dev/null || echo "no disponible"
	@echo "DOCKER_HOST=$$DOCKER_HOST"
	@echo "Sugerencia: ejecutar en macOS/Linux o Windows con WSL2. Si 'docker run -v \"$$PWD\":/work' no ve el repo, use 'make use-host-docker'."

# -------- Builds de imagen --------
.PHONY: build-in-minikube build-host load-image
build-in-minikube: use-minikube-docker ## Construye imagen dentro de minikube
	@echo "[BUILD] Build dentro de Minikube"
	docker build -t $(IMAGE):$(IMAGE_VERSION) .

build-host: use-host-docker ## Construye imagen en host
	@echo "[BUILD] Build en host"
	docker build -t $(IMAGE):$(IMAGE_VERSION) .
load-image: ## Carga la imagen al cluster de Minikube
	@echo "[UPLOAD] Cargando imagen al cluster"
	minikube image load $(IMAGE):$(IMAGE_VERSION)

# -------- Buildx (multi-arch) --------
.PHONY: buildx-create buildx-use buildx-inspect imagetools-inspect buildx-push
buildx-create: use-host-docker ## Crea y selecciona un builder buildx (si no existe) y hace bootstrap
	@docker buildx inspect xbuilder >/dev/null 2>&1 || docker buildx create --name xbuilder --use
	docker buildx use xbuilder
	docker buildx inspect --bootstrap

buildx-use: use-host-docker ## Selecciona el builder xbuilder si existe
	docker buildx use xbuilder || { echo "[ERROR] Builder xbuilder no existe. Ejecute 'make buildx-create'"; exit 1; }

buildx-inspect: ## Muestra información del builder activo
	docker buildx inspect

imagetools-inspect: ## Inspecciona el manifest multi-arch de la imagen publicada
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	docker buildx imagetools inspect $(GHCR_IMAGE):$(IMAGE_VERSION)

# -------- Publicación en GHCR --------
.PHONY: ghcr-login ghcr-tag ghcr-push ghcr-publish ghcr-inspect update-values
ghcr-login: ## Inicia sesión en GHCR usando GH_USER y GH_TOKEN (variable de entorno)
	@if [ -z "$$GH_USER" ] || [ -z "$$GH_TOKEN" ]; then \
	  echo "[ERROR] Debe definir GH_USER y GH_TOKEN en el entorno"; exit 1; \
	fi
	@echo "$$GH_TOKEN" | docker login $(GHCR_REG) -u $(GH_USER) --password-stdin

ghcr-tag: ## Etiqueta la imagen local para GHCR
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	docker tag $(IMAGE):$(IMAGE_VERSION) $(GHCR_IMAGE):$(IMAGE_VERSION)

ghcr-push: ## Publica la imagen en GHCR con tag inmutable
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	docker push $(GHCR_IMAGE):$(IMAGE_VERSION)
ghcr-publish: ## Publica en GHCR (multi-arch por defecto). Use MULTIARCH=false para single-arch
ifeq ($(MULTIARCH),false)
	$(MAKE) ghcr-login ghcr-tag ghcr-push
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	@echo "[INFO] Actualizando $(VALUES_FILE) con repository en GHCR (vía yq en contenedor)"
	docker run --rm -v "$$PWD":/work -w /work \
	  mikefarah/yq:4 \
	  -i '.image.repository = "ghcr.io/$(GH_USER)/$(IMAGE)"' $(VALUES_FILE)
	@echo "[INFO] Actualizando $(VALUES_FILE) con tag (vía yq en contenedor)"
	docker run --rm -v "$$PWD":/work -w /work \
	  mikefarah/yq:4 \
	  -i '.image.tag = "$(IMAGE_VERSION)"' $(VALUES_FILE)
	@echo "[OK] $(VALUES_FILE) actualizado con GHCR=ghcr.io/$(GH_USER)/$(IMAGE) y tag=$(IMAGE_VERSION)"
else
	@echo "[INFO] MULTIARCH=$(MULTIARCH) → ejecutando buildx-push"
	$(MAKE) buildx-push
endif

update-values: ## Actualiza repository/tag en values.yaml usando yq en contenedor
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	@echo "[INFO] Actualizando $(VALUES_FILE) con repository/tag en GHCR (vía yq en contenedor)"
	docker run --rm -v "$$PWD":/work -w /work mikefarah/yq:4 \
	  -i '.image.repository = "ghcr.io/$(GH_USER)/$(IMAGE)"' $(VALUES_FILE)
	docker run --rm -v "$$PWD":/work -w /work mikefarah/yq:4 \
	  -i '.image.tag = "$(IMAGE_VERSION)"' $(VALUES_FILE)
	@echo "[OK] $(VALUES_FILE) actualizado con GHCR=ghcr.io/$(GH_USER)/$(IMAGE) y tag=$(IMAGE_VERSION)"

ghcr-inspect: ## Verifica digest de la imagen publicada en GHCR
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	docker pull $(GHCR_IMAGE):$(IMAGE_VERSION)
	docker image inspect $(GHCR_IMAGE):$(IMAGE_VERSION) --format '{{.RepoDigests}}'

# -------- Render (Helm en contenedor) --------
.PHONY: render
render: _ensure-dirs use-host-docker ## Renderiza chart Helm
	@echo "[INFO] Renderizando chart → $(RENDER_FILE)"
	docker run --rm -v "$$PWD":/work -w /work \
	  $(HELM_IMG) template $(RELEASE) ./$(CHART_DIR) \
	  -n $(NAMESPACE) \
	  --set config.appVersion=$(APP_VERSION) \	  
	  --values ./$(VALUES_FILE) \
	  > $(RENDER_FILE)
	@echo "[OK] Render listo: $(RENDER_FILE)"

# -------- Apply / Uninstall --------
.PHONY: apply uninstall delete-ns
apply: ## Aplica la configuración en Kubernetes
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(NAMESPACE) -f $(RENDER_FILE)
	kubectl get deploy,po,svc -n $(NAMESPACE)

uninstall: ## Desinstala la aplicación del cluster
	- kubectl delete -n $(NAMESPACE) -f $(RENDER_FILE) --ignore-not-found=true

delete-ns: ## Elimina el namespace configurado
	- kubectl delete ns $(NAMESPACE) --ignore-not-found=true

# -------- Smoke test --------
.PHONY: port-forward smoke
port-forward: ## Hace port-forward del Deployment
	@echo "[FORWARD] Port-forward (Ctrl+C para detener)"
	kubectl -n $(NAMESPACE) port-forward deploy/$(RELEASE)-traveltrack-api 8080:8080

smoke: ## Pruebas rápidas de la aplicación
	@echo "[TEST] Pruebas rápidas"
	@kubectl -n $(NAMESPACE) get deploy,po,svc
	@kubectl -n $(NAMESPACE) port-forward deploy/$(RELEASE)-traveltrack-api 8080:8080 >/dev/null 2>&1 & \
	PID=$$!; \
	sleep 2; \
	echo "# /health"; curl -s localhost:8080/health || true; echo; \
	echo "# /api/version"; curl -s localhost:8080/api/version || true; echo; \
	kill $$PID >/dev/null 2>&1 || true

# -------- Limpieza --------
.PHONY: clean
clean: ## Limpia archivos generados
	- rm -f $(RENDER_FILE)
	@echo "[CLEAN] Limpieza completada"
# -------- Publicar multi-arch en GHCR --------
.PHONY: buildx-push
buildx-push: buildx-create ghcr-login ## Construye y publica imagen multi-arch (linux/amd64,linux/arm64) en GHCR [ruta por defecto de ghcr-publish]
	@if [ -z "$(GH_USER)" ]; then echo "[ERROR] GH_USER no definido"; exit 1; fi
	@echo "[BUILD] Buildx multi-arch: $(PLATFORMS) -> $(GHCR_IMAGE):$(IMAGE_VERSION)"
	docker buildx build \
	  --platform $(PLATFORMS) \
	  -t $(GHCR_IMAGE):$(IMAGE_VERSION) \
	  --push \
	  .
	@echo "[OK] Publicado: $(GHCR_IMAGE):$(IMAGE_VERSION)"
	@echo "[INFO] Actualizando $(VALUES_FILE) con repository y tag"
	docker run --rm -v "$$PWD":/work -w /work \
	  mikefarah/yq:4 \
	  -i '.image.repository = "ghcr.io/$(GH_USER)/$(IMAGE)"' $(VALUES_FILE)
	docker run --rm -v "$$PWD":/work -w /work \
	  mikefarah/yq:4 \
	  -i '.image.tag = "$(IMAGE_VERSION)"' $(VALUES_FILE)
	@echo "[OK] $(VALUES_FILE) actualizado con GHCR=ghcr.io/$(GH_USER)/$(IMAGE) y tag=$(IMAGE_VERSION)"
# -------- Mostrar versiones --------
.PHONY: print-version
print-version: ## Muestra la versión actual de la imagen y de la aplicación
	@echo "IMAGE_VERSION = $(IMAGE_VERSION)"
	@echo "APP_VERSION   = $(APP_VERSION)"