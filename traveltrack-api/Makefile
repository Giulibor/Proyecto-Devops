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
.SHELLFLAGS := -eu -o pipefail -c

.DEFAULT_GOAL := help

.PHONY: help
help: ## Muestra esta ayuda con la lista de comandos disponibles
	@echo "make <target>"
	@grep -hE '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

# -------- Variables --------
# Cargar variables desde .env si existe
ifneq ("$(wildcard .env)","")
  include .env
  export
endif

# Si alguna variable no está definida, asignar valores por defecto
IMAGE_VERSION ?= auto
APP_VERSION   ?= 1.0.0

IMAGE         ?= traveltrack-api
NAMESPACE     ?= traveltrack
RELEASE       ?= tt

CHART_DIR     := charts/traveltrack-api
DEPLOY_DIR    := deploy
RENDER_FILE   := $(DEPLOY_DIR)/tt.yaml
VALUES_FILE   := $(CHART_DIR)/values.yaml

HELM_IMG      ?= alpine/helm:3.19.0

# -------- Buildx / Multi-arch --------
PLATFORMS     ?= linux/amd64,linux/arm64
# Multi-arch por defecto (true|false)
MULTIARCH    ?= true

# -------- GHCR (GitHub Container Registry) --------
GH_USER       ?= 
GHCR_REG      ?= ghcr.io
GHCR_IMAGE    := $(GHCR_REG)/$(GH_USER)/$(IMAGE)

# -------- Kyverno --------
KYVERNO_NS ?= kyverno
KYVERNO_LOG := reports/kyverno.log

# Si IMAGE_VERSION=auto → generar timestamp y persistir en .env
ifeq ($(IMAGE_VERSION),auto)
  IMAGE_VERSION := $(shell date +"%Y.%m.%d.%H.%M")
  $(shell sed -i'' -E 's/^IMAGE_VERSION=.*/IMAGE_VERSION=$(IMAGE_VERSION)/' .env 2>/dev/null || echo "IMAGE_VERSION=$(IMAGE_VERSION)" >> .env)
endif

.PHONY: _ensure-dirs
_ensure-dirs:
	@mkdir -p $(DEPLOY_DIR)
	@if [ ! -d "$(CHART_DIR)" ]; then \
	  echo "[ERROR] No se encuentra el chart en $(CHART_DIR)"; \
	  exit 1; \
	fi

# -------- Targets compuestos de alto nivel --------
.PHONY: deploy-from-local-build deploy-from-ghcr security-checks full-pipeline

deploy-from-local-build: build-in-minikube load-image render apply smoke
	@echo "[DONE] deploy-local-build completo (build local + load-image + deploy + smoke)"

deploy-from-ghcr: start-minikube render apply smoke
	@echo "[DONE] deploy-local completo (usando imagen configurada en values.yaml, típicamente GHCR)"

security-checks: kubelinter-scan kyverno-apply kyverno-test-bad kyverno-test-good
	@echo "[DONE] security-checks completo"

full-pipeline: doctor deploy-local-build security-checks
	@echo "[DONE] full-pipeline completo"

# -------- Minikube --------
.PHONY: start-minikube stop-minikube status
start-minikube: ## Inicia minikube
	minikube start --driver=docker --memory=2048 --cpus=2

stop-minikube: ## Detiene minikube
	minikube stop

status: ## Muestra estado de minikube y nodos
	minikube status
	kubectl get nodes

# -------- Alternar Docker daemon --------
.PHONY: use-minikube-docker use-host-docker which-docker doctor
use-minikube-docker: ## Cambia Docker CLI al daemon de Minikube
	@eval "$$(minikube -p minikube docker-env)"; \
	echo "[OK] Docker CLI apuntando al daemon de Minikube."; \
	docker info | grep -i 'name' || true

use-host-docker: ## Restaura Docker CLI del host
	@eval "$$(minikube -p minikube docker-env -u)"; \
	echo "[OK] Docker CLI de tu host restaurado."; \
	docker info | grep -i 'name' || true

which-docker: ## Indica a qué daemon Docker apunta la CLI
	@echo "DOCKER_HOST=$$DOCKER_HOST"
	@docker info | grep -i 'name' || true

doctor: ## Diagnóstico rápido del entorno (Docker, Minikube, kubectl, buildx)
	@echo "=== DOCTOR ==="
	@echo "[OS] uname -s: $$(uname -s)"
	@echo "[Docker] version:"; docker version --format '{{.Server.Version}}' 2>/dev/null || echo "no disponible"
	@echo "[Docker] daemon name:"; docker info 2>/devnull | grep -i '^ name' || echo "no disponible"
	@echo "[kubectl] client:"; kubectl version --client --short 2>/dev/null || echo "no disponible"
	@echo "[minikube] version:"; minikube version 2>/dev/null || echo "no disponible"
	@echo "[buildx] info:"; docker buildx version 2>/dev/null || echo "no disponible"
	@echo "DOCKER_HOST=$$DOCKER_HOST"
	@echo "Sugerencia: ejecutar en macOS/Linux o Windows con WSL2. Si 'docker run -v \"$$PWD\":/work' no ve el repo, use 'make use-host-docker'."

# -------- Builds de imagen --------
.PHONY: build-in-minikube build-host load-image
build-in-minikube: start-minikube use-minikube-docker ## Construye imagen dentro de minikube
	@echo "[BUILD] Build dentro de Minikube"
	docker build -t $(IMAGE):$(IMAGE_VERSION) .

build-host: use-host-docker ## Construye imagen en host
	@echo "[BUILD] Build en host"
	docker build -t $(IMAGE):$(IMAGE_VERSION) .
load-image: ## Carga la imagen al cluster de Minikube
	@echo "[UPLOAD] Cargando imagen al cluster"
	minikube image load $(IMAGE):$(IMAGE_VERSION)

# -------- Buildx (multi-arch) --------
.PHONY: buildx-create buildx-use buildx-inspect imagetools-inspect
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
	$(MAKE) ghcr-login ghcr-tag ghcr-push update-values
else
	@echo "[INFO] MULTIARCH=$(MULTIARCH) → ejecutando buildx-push"
	$(MAKE) buildx-push update-values
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
	  --values ./$(VALUES_FILE) \
	  --set-string config.APP_VERSION=$(APP_VERSION) \
	  > $(RENDER_FILE)
	@echo "[OK] Render listo: $(RENDER_FILE)"

# -------- Apply / Uninstall --------
.PHONY: apply uninstall delete-ns
apply: ## Aplica la configuración en Kubernetes
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(NAMESPACE) -f $(RENDER_FILE)
	sleep 20
	kubectl get deploy,po,svc -n $(NAMESPACE)

uninstall: ## Desinstala la aplicación del cluster
	- kubectl delete -n $(NAMESPACE) -f $(RENDER_FILE) --ignore-not-found=true

delete-ns: ## Elimina el namespace configurado
	- kubectl delete ns $(NAMESPACE) --ignore-not-found=true

# -------- Smoke test --------
.PHONY: port-forward smoke
port-forward: ## Hace port-forward del Deployment
	@echo "[FORWARD] Port-forward (Ctrl+C para detener)"
	kubectl -n $(NAMESPACE) port-forward svc/traveltrack-api 8080:8080

smoke: ## Pruebas rápidas de la aplicación
	@echo "[TEST] Pruebas rápidas"
	@kubectl -n $(NAMESPACE) get deploy,po,svc
	@kubectl -n $(NAMESPACE) port-forward svc/traveltrack-api 8080:8080 >/dev/null 2>&1 & \
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

# -------- Mostrar versiones --------
.PHONY: print-version
print-version: ## Muestra la versión actual de la imagen y de la aplicación
	@echo "IMAGE_VERSION = $(IMAGE_VERSION)"
	@echo "APP_VERSION   = $(APP_VERSION)"

# Detectar si IMAGE_VERSION vino por CLI (no hacer bump en ese caso)
ifeq ($(origin IMAGE_VERSION), command line)
  SKIP_BUMP := 1
endif

# Bump de versión (YYYY.MM.DD.HH.MM) y persistencia en .env
.PHONY: bump-image-version
bump-image-version:
ifndef SKIP_BUMP
	@echo "[VERSION] Generando nuevo IMAGE_VERSION…"
	@ts=$$(date +"%Y.%m.%d.%H.%M"); \
	  if [ -f .env ] && grep -q '^IMAGE_VERSION=' .env; then \
	    sed -i'' -E "s/^IMAGE_VERSION=.*/IMAGE_VERSION=$$ts/" .env; \
	  else \
	    echo "IMAGE_VERSION=$$ts" >> .env; \
	  fi; \
	  echo "[VERSION] IMAGE_VERSION=$$ts"
	# Refrescar variable dentro de make
	$(eval IMAGE_VERSION := $(shell grep '^IMAGE_VERSION=' .env | cut -d= -f2))
else
	@echo "[VERSION] Usando IMAGE_VERSION pasado por CLI: $(IMAGE_VERSION)"
endif

# -------- Kyverno install --------
.PHONY: kyverno-install-kubectl
kyverno-install-kubectl: ## Instala Kyverno en el cluster vía kubectl (delete+create)
	@echo "[INSTALL] Instalando Kyverno en el cluster (namespace: $(KYVERNO_NS))"
	@echo "[INSTALL] Limpiando recursos previos de Kyverno (si existieran)..."
	- kubectl delete -f https://github.com/kyverno/kyverno/releases/download/v1.16.0/install.yaml --ignore-not-found=true || true
	kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.16.0/install.yaml
	sleep 20
	kubectl -n $(KYVERNO_NS) get deploy,po

kyverno-uninstall: ## Borra completamente Kyverno del cluster (usa con cuidado)
	@echo "[KYVERNO] Eliminando recursos de Kyverno usando el manifest oficial..."
	- kubectl delete -f https://github.com/kyverno/kyverno/releases/download/v1.16.0/install.yaml --ignore-not-found=true || true
	@echo "[KYVERNO] Eliminando namespace kyverno (si sigue existiendo)..."
	- kubectl delete ns kyverno --ignore-not-found=true || true
	@echo "[KYVERNO] Kyverno eliminado. Podés reinstalar con 'make kyverno-install-kubectl'."

# -------- Kyverno policies testing --------
.PHONY: kyverno-apply kyverno-test-bad kyverno-test-good kyverno-clean kyverno-reset

kyverno-apply: ## Aplica políticas y lista cpol
	@mkdir -p reports
	kubectl apply -f kyverno-policies/ | tee -a $(KYVERNO_LOG)
	kubectl get cpol | tee -a $(KYVERNO_LOG)
	@echo "----" >> $(KYVERNO_LOG)

kyverno-test-bad: ## Intenta deploy no conforme y guarda evidencia en kyverno.log
	@mkdir -p reports
	@echo "[TEST BAD] Intentando aplicar kyverno-tests/bad-pod.yaml" | tee -a $(KYVERNO_LOG)
	- kubectl apply -f kyverno-tests/bad-pod.yaml -n $(NAMESPACE) >> $(KYVERNO_LOG) 2>&1 || true
	sleep 20
	kubectl -n $(NAMESPACE) get pod bad-pod -o wide | tee -a $(KYVERNO_LOG)
	@echo "----" >> $(KYVERNO_LOG)

kyverno-test-good: ## Deploy conforme y registrar evidencia en kyverno.log
	@mkdir -p reports
	@echo "[TEST GOOD] Aplicando kyverno-tests/good-pod.yaml" | tee -a $(KYVERNO_LOG)
	kubectl delete pod good-pod -n $(NAMESPACE) --ignore-not-found=true >> $(KYVERNO_LOG) 2>&1
	kubectl apply -f kyverno-tests/good-pod.yaml -n $(NAMESPACE) | tee -a $(KYVERNO_LOG)
	sleep 20
	kubectl -n $(NAMESPACE) get pod good-pod -o wide | tee -a $(KYVERNO_LOG)
	@echo "----" >> $(KYVERNO_LOG)

kyverno-clean: ## Limpia pods de prueba
	- kubectl delete -f kyverno-tests/bad-pod.yaml -n $(NAMESPACE) --ignore-not-found=true >> $(KYVERNO_LOG) 2>&1
	- kubectl delete -f kyverno-tests/good-pod.yaml -n $(NAMESPACE) --ignore-not-found=true >> $(KYVERNO_LOG) 2>&1
	@echo "[CLEAN] Pods de prueba eliminados" | tee -a $(KYVERNO_LOG)
	@echo "----" >> $(KYVERNO_LOG)

kyverno-reset: ## Borra todas las ClusterPolicy y reaplica desde policies/
	@mkdir -p reports
	@echo "[RESET] Eliminando todas las ClusterPolicy" | tee -a $(KYVERNO_LOG)
	- kubectl get cpol -o name | xargs -r kubectl delete >> $(KYVERNO_LOG) 2>&1
	@echo "[RESET] Reaplicando policies desde ./kyverno-policies/" | tee -a $(KYVERNO_LOG)
	kubectl apply -f kyverno-policies/ | tee -a $(KYVERNO_LOG)
	kubectl get cpol | tee -a $(KYVERNO_LOG)
	@echo "----" >> $(KYVERNO_LOG)

# -------- Trivy scan --------
.PHONY: trivy-scan trivy-summary dive-image
trivy-scan: use-host-docker ## Ejecuta Trivy sobre la imagen actual y genera reports/trivy-report.json
	@if [ -z "$(GH_USER)" ]; then \
	  echo "[ERROR] GH_USER no definido. Defínelo en .env o en el entorno."; \
	  exit 1; \
	fi
	@echo "[TRIVY] Escaneando imagen $(GHCR_IMAGE):$(IMAGE_VERSION)"
	@mkdir -p reports
	docker run --rm \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v "$$PWD":/work \
	  -w /work \
	  aquasec/trivy:latest \
	  image $(GHCR_IMAGE):$(IMAGE_VERSION) \
	  --scanners vuln \
	  --format json > reports/trivy-report.json
	@echo "[TRIVY] Reporte generado en reports/trivy-report.json"

trivy-summary: ## Muestra resumen HIGH/CRITICAL del reporte Trivy o mensaje si está vacío
	@if [ ! -f reports/trivy-report.json ]; then \
		echo "[ERROR] No existe reports/trivy-report.json. Primero ejecutar: make trivy-scan"; \
		exit 1; \
	fi; \
	jq_output=$$( jq '.Results[].Vulnerabilities // [] \
		| .[] \
		| select(.Severity=="HIGH" or .Severity=="CRITICAL") \
		| {id: .VulnerabilityID, pkg: .PkgName, severity: .Severity, installed: .InstalledVersion, fixed: .FixedVersion}' \
		reports/trivy-report.json ); \
	if [ -z "$$jq_output" ]; then \
		echo "[TRIVY] No hay vulnerabilidades HIGH/CRITICAL."; \
	else \
		echo "$$jq_output"; \
	fi

dive-image: use-host-docker ## Analiza la imagen actual con Dive (TUI interactiva)
	@if [ -z "$(GH_USER)" ]; then \
	  echo "[ERROR] GH_USER no definido. Defínelo en .env o en el entorno."; \
	  exit 1; \
	fi
	@echo "[DIVE] Descargando imagen $(GHCR_IMAGE):$(IMAGE_VERSION) si no está local..."
	docker pull $(GHCR_IMAGE):$(IMAGE_VERSION)
	@echo "[DIVE] Lanzando Dive sobre $(GHCR_IMAGE):$(IMAGE_VERSION)"
	docker run --rm -it \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  wagoodman/dive:latest \
	  $(GHCR_IMAGE):$(IMAGE_VERSION)

# -------- KubeLinter scan --------
.PHONY: kubelinter-scan
kubelinter-scan: ## Ejecuta KubeLinter contra deploy/tt.yaml y genera reports/kubelinter.txt
	@if [ ! -f deploy/tt.yaml ]; then \
		echo "Manifiesto no encontrado, ejecutando make render..."; \
		$(MAKE) render; \
	fi

	@mkdir -p reports

	@docker run --rm \
		-v $(PWD):/work \
		-w /work \
		ghcr.io/stackrox/kube-linter:latest \
		lint deploy/tt.yaml > reports/kubelinter.txt

	@echo "✔ KubeLinter completado → reports/kubelinter.txt"

# -------- Falco install and testing --------
.PHONY: falco-install falco-trigger falco-logs falco-uninstall
falco-install: ## Instala Falco en el cluster Minikube usando Helm (templating) + kubectl
	@echo "Instalando Falco..."
	@kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
	@mkdir -p deploy

	docker run --rm \
		-v $(PWD):/work \
		-w /work \
		--entrypoint sh \
		$(HELM_IMG) -c "helm repo add falcosecurity https://falcosecurity.github.io/charts && \
		                helm repo update && \
		                helm template falco falcosecurity/falco \
							--namespace falco \
							--set driver.kind=modern-bpf \
							> deploy/falco.yaml"

	@echo "[APPLY] Aplicando manifiestos de Falco desde deploy/falco.yaml"
	kubectl apply -n falco -f deploy/falco.yaml

	@echo "✔ Falco instalado en namespace falco (vía helm template + kubectl apply)"

falco-trigger: ## Genera un evento sospechoso ejecutando un shell dentro de un pod
	@echo "Generando un evento sospechoso..."
	@POD=$$(kubectl get pods -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
	  echo "[ERROR] No se encontró ningún pod en el namespace $(NAMESPACE)"; \
	  exit 1; \
	fi; \
	echo "Ejecutando: kubectl exec -it $$POD -- sh -c 'id; sleep 1'"; \
	kubectl exec -it -n $(NAMESPACE) $$POD -- sh -c "id; sleep 1" || true
	@echo "✔ Evento generado"

falco-logs: ## Extrae logs de Falco a reports/falco-event.log
	@echo "Extrayendo logs de Falco..."
	@mkdir -p reports
	@POD=$$(kubectl get pods -n falco -o jsonpath='{.items[0].metadata.name}'); \
	if [ -z "$$POD" ]; then \
	  echo "[ERROR] No se encontró ningún pod en el namespace falco"; \
	  kubectl get pods -n falco; \
	  exit 1; \
	fi; \
	echo "[INFO] Usando pod: $$POD"; \
	kubectl logs -n falco $$POD > reports/falco-event.log
	@echo "✔ Logs guardados en reports/falco-event.log"

falco-uninstall: ## Desinstala Falco eliminando el namespace falco
	@echo "🧹 Desinstalando Falco..."
	kubectl delete namespace falco --ignore-not-found=true
	@echo "✔ Falco desinstalado"