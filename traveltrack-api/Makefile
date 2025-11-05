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
VERSION      ?= 0.1.0
IMAGE        ?= traveltrack-api
NAMESPACE    ?= traveltrack
RELEASE      ?= tt

CHART_DIR    := charts/traveltrack-api
DEPLOY_DIR   := deploy
RENDER_FILE  := $(DEPLOY_DIR)/tt.yaml
VALUES_FILE  := $(CHART_DIR)/values.yaml

HELM_IMG     ?= alpine/helm:3.15.3

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

status:
	minikube status
	kubectl get nodes

# -------- Alternar Docker daemon --------
.PHONY: use-minikube-docker use-host-docker which-docker
use-minikube-docker:
	@eval "$$(minikube docker-env)"; \
	echo "[OK] Docker CLI apuntando al daemon de Minikube."; \
	docker info | grep -i 'name' || true

use-host-docker:
	@eval "$$(minikube docker-env -u)"; \
	echo "[OK] Docker CLI de tu host restaurado."; \
	docker info | grep -i 'name' || true

which-docker:
	@echo "DOCKER_HOST=$$DOCKER_HOST"
	@docker info | grep -i 'name' || true

# -------- Builds de imagen --------
.PHONY: build-in-minikube build-host load-image
build-in-minikube: use-minikube-docker ## Construye imagen dentro de minikube
	@echo "[BUILD] Build dentro de Minikube"
	docker build -t $(IMAGE):$(VERSION) .

build-host: use-host-docker ## Construye imagen en host
	@echo "[BUILD] Build en host"
	docker build -t $(IMAGE):$(VERSION) .

load-image:
	@echo "[UPLOAD] Cargando imagen al cluster"
	minikube image load $(IMAGE):$(VERSION)

# -------- Render (Helm en contenedor) --------
.PHONY: render
render: _ensure-dirs use-host-docker ## Renderiza chart Helm
	@echo "[INFO] Renderizando chart → $(RENDER_FILE)"
	docker run --rm -v "$$PWD":/work -w /work \
	  $(HELM_IMG) template $(RELEASE) ./$(CHART_DIR) \
	  -n $(NAMESPACE) \
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

delete-ns:
	- kubectl delete ns $(NAMESPACE) --ignore-not-found=true

# -------- Smoke test --------
.PHONY: port-forward smoke
port-forward:
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