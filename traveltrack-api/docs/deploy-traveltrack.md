# Guía de Deploy — TravelTrack API

Esta guía describe el flujo estándar para **construir, publicar y probar la imagen de la API TravelTrack**.

---

## 0) (Opcional) Requisitos rápidos

Verificar que las variables y versiones estén correctamente configuradas:

```bash
make print-version
```

---
# Etapa 1
## 1) Preparación

Cargar credenciales y validar el acceso a GitHub Container Registry (GHCR):

```bash
echo "$GH_USER"
test -n "$GH_TOKEN" && echo "OK TOKEN" || echo "FALTA TOKEN"
make ghcr-login
```

- `GH_USER`: usuario de GitHub.
    
- `GH_TOKEN`: token personal con permisos `write:packages`.
    
- `make ghcr-login`: autentica el cliente Docker en GHCR.
    

---

## 2) Build multi-arquitectura + Push

Construir la imagen para `amd64` y `arm64`, y publicarla directamente en GHCR:

```bash
make buildx-push
```

Este comando:

- Genera automáticamente `IMAGE_VERSION` (fecha/hora si está en `auto`).
    
- Compila para múltiples arquitecturas (`linux/amd64`, `linux/arm64`).
    
- Sube la imagen a `ghcr.io/$GH_USER/traveltrack-api:$IMAGE_VERSION`.
    

---

## 3) Verificación de publicación

Inspeccionar el manifiesto publicado y confirmar las arquitecturas disponibles:

```bash
make imagetools-inspect
```

Debe mostrar al menos las variantes `linux/amd64` y `linux/arm64`.

---
# Etapa 2+3
## 4) Despliegue en Kubernetes con Helm

### 4.0 Iniciar Minikube

``` bash
make start-minikube
```

### 4.1 render
Renderiza chart Helm

eval $(minikube docker-env -u)

```bash
make render
```


### 4.2 aplicar
Aplica la configuración en Kubernetes

```bash
make apply
```

---

### 4.3 port-forward

``` bash
make port-forward
```

---

## 5) Test

Verificar que la aplicación responde correctamente:

```bash
make smoke
```


- `/health`: debe devolver un estado OK.
    
- `/api/version`: debe reflejar la versión actual (`APP_VERSION` o `IMAGE_VERSION`).

Si las respuestas son correctas, la aplicación está corriendo dentro del cluster.

---
# Etapa 4
## 6) Kyverno - Instalación y validación

```bash
make kyverno-install-kubectl
make kyverno-apply

(reset)
make kyverno-reset

(opcional)
make kyverno-test-bad
make kyverno-test-good
(clean)
make kyverno-clean

(uninstall)
make kyverno-uninstall
```

El reporte queda en `traveltrack-api/reports/kyverno.log`

---

# Etapa 5

## a) npm audit → Seguridad de dependencias

0) confirmar que las dependiencias ya estan instaladas
```bash
cd traveltrack-api
npm install

```

1) ejecutar análisis
```bash
npm audit --json > reports/npm-audit.txt

```

2) validacion
```bash
less reports/npm-audit.txt
```
o
```bash
cat reports/npm-audit.txt | jq '.'
```


## b) Trivy → Vulnerabilidades en la imagen


1) correr Trivy desde docker
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD:/work \
  -w /work \
  aquasec/trivy:latest \
  image ghcr.io/cardo88/traveltrack-api:$IMAGE_VERSION \
  --format json > reports/trivy-report.json
```

2) validar reporte, filtrado por high o critical, y solo con campos interesantes
```bash
jq '.Results[].Vulnerabilities // [] 
    | .[] 
    | select(.Severity=="HIGH" or .Severity=="CRITICAL") 
    | {id: .VulnerabilityID, pkg: .PkgName, severity: .Severity, installed: .InstalledVersion, fixed: .FixedVersion}' \
    reports/trivy-report.json
```


## c) SlimToolkit/Dive → Composición y optimización de capas

```bash
eval $(minikube -p minikube docker-env -u)
```

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/work \
  -w /work \
  dslim/docker-slim:latest \
  xray --pull \
       --target ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58
```

probando con Dive
```bash
docker pull ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58
docker image ls ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58
```

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest \
  ghcr.io/cardo88/traveltrack-api:2025.11.15.15.58
```


---
# Etapa 6

> docker apuntando a docker

## Ejecutar la validación

Una vez agregado el target:
```
make kubelinter-scan
```

Esto generará:

`reports/kubelinter.txt`


---

# Etapa 7 - Falco

> Docker como minikube
> Debe estar traveltrack corriendo

1. Instalar Falco en Minikube
	- Crea el namespace falco
	- Agrega el repo Helm (dentro del contenedor helm)
	- Instala Falco con los valores por defecto
	- No instala nada en la compu
2. Generar un evento sospechoso (por ejemplo, abrir un shell dentro de un pod)
    - Entrar a un pod en modo shell (sh)
	- Esto genera la regla “Terminal shell in container” o similar
3. Extraer los logs a reports/falco-event.log
    - Se capturan las últimas líneas del daemon de Falco.
4. Desinstalar Falco para no dejarlo corriendo

Comandos:
``` bash
make falco-install
sleep 20
kubectl get pods -n falco
make falco-trigger
sleep 5
make falco-logs
make falco-uninstall
```

Genera reporte en `reports/falco-event.log`

> Para la parte de monitoreo en tiempo de ejecución se instaló Falco mediante Helm en el namespace falco, utilizando helm template y kubectl apply.
> 
> Luego se ejecutó un comando controlado (kubectl exec ... sh -c "id") dentro de un pod del namespace traveltrack para simular la apertura de un shell en un contenedor, que es una de las situaciones monitoreadas por las reglas por defecto de Falco.
> 
> Los logs del daemon de Falco se recopilaron en reports/falco-event.log. En ellos se observa que Falco inicia correctamente, carga su configuración y reglas (falco_rules.yaml), pero al intentar adjuntar los BPF programs a los tracepoints del kernel se registran errores de libbpf/libpman indicando que no encuentra los eventos de syscall esperados.
> 
> Esto se debe a limitaciones del entorno de ejecución (Minikube sobre macOS/Docker), donde el kernel de la VM no expone todos los tracepoints necesarios para el engine BPF de Falco. Como consecuencia, en este entorno no se llegan a registrar alertas de reglas, aunque el flujo de instalación, generación de evento sospechoso y recolección de evidencia está implementado y reproducible.

### Limitaciones del entorno con Falco

Falco se inicializa correctamente, carga su configuración y reglas, y arranca el engine modern-bpf. Sin embargo, en este entorno (Minikube sobre macOS/Docker Desktop) el kernel de la VM no expone todos los tracepoints necesarios para la instrumentación de syscalls. Esto genera mensajes de libbpf/libpman indicando que no se encuentran ciertos eventos (sys_enter_*), lo cual impide que algunas reglas disparen alertas.

Este comportamiento es conocido en setups basados en LinuxKit/Docker Desktop, donde el kernel virtualizado presenta soporte BPF parcial. A pesar de ello:
- El despliegue de Falco es reproducible
- El evento sospechoso se genera correctamente
- Los logs del daemon quedan almacenados como evidencia


---
# Limpieza del entorno

#### 7.1 Borrar el namespace de travletrack

```bash
kubectl delete namespace traveltrack
```

#### 7.2 Apagar minikube

```bash
make stop-minikube
```



# arreglar:
- [ ] que no se gernere una nueva version cada vez, sino qeu se genere solo cuando se pushea, luego conserve esa version en algun lugar (.log tal vez)
- [ ] arreglar el tema de cuando usar docker para docker y cuando para minikube
- [ ] cada vez que hago algo con -rm, no esta matando ese docker.
- [ ] mejorar el smoke, solo esta probando si esta levantado, hay que probar las demas interfaces solicitadas.
- [ ] cambiar tt.yaml por traveltrack.yaml
- [ ] cambiar el make apply por make helm apply, o algo por el estilo.
- [ ] revision del makefile, si estan bien los .phony


ayuda memoria

eval $(minikube docker-env)
eval $(minikube docker-env -u)
