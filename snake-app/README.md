# Proyecto-Devops

## Entrega 1

Contiene un ejemplo práctico de despliegue **Blue/Green** en Kubernetes utilizando **Minikube** y **Docker** como entorno local.
La aplicación base es una versión simple del juego Snake en Angular.

## Scripts disponibles

### El flujo recomendado

- `cd snake-app/scripts`
- `sh 01_up.sh`
  - salir con `Ctrl + C`
- `sh 02_rollout.sh green`
  - salir con `Ctrl + C`
- `sh 02_rollout.sh blue`
  - salir con `Ctrl + C`
    - (repetir los dos pasos anteriores las veces que se requiera.)
- `sh 03_down.sh`.

> ⚠️ **Nota:** Si bien se ha reestructurado el repositorio, **los scripts pueden ejecutarse desde cualquier directorio**.


### Funcion de cada script

Los scripts se encuentran en el directorio `snake-app/scripts`, su objetivo es la automatizacion de tareas comunes:

- `01_up.sh`:
  - **Propopsito:** Prepara el ambiente completo, inicia Minikube, limpia recursos previos, ejecuta el build de imágenes llamando a `01b_build_images.sh`, aplica los manifiestos y abre el Service.  
  - **Uso:** Este script deja abierto el comando `minikube service snake-app`, que muestra la URL del servicio en el navegador. Para finalizar este comando y cerrar el servicio, es necesario presionar `Ctrl+C`.
- `01b_build_images.sh`:
  - **Propopsito:** Construye automáticamente las imágenes blue (v1) y green (v2), modificando el H1 del HMTL del archivo `snake-app/src/app/app.component.html`HTML, generando previamente un backup.
- `02_rollout.sh`:
  - **Propopsito:** Permite cambiar el Service entre blue y green y abrir el navegador para validar el cambio.  
  - **Uso:** Se debe invocar con un argumento que indique la versión deseada, `blue` o `green`, por ejemplo: `sh 02_rollout.sh green`. Este script también deja abierto el comando `minikube service snake-app` para visualizar el cambio. Para cerrar este comando y el servicio, presionar `Ctrl+C`.
- `03_down.sh`:
  - **Propopsito:** Limpia todo (deploys, services, pods), detiene Minikube y revierte las variables de entorno de Docker.

---

## Comando utilizados

### Arranque de Minikube

> Inicia un clúster local de Kubernetes con Minikube, utilizando Docker como proveedor de máquinas virtuales.

```bash
minikube start --driver=docker
```


> Configura tu Docker local para que use el demonio de Docker interno de Minikube.

**En MacOS:**

```bash
eval $(minikube docker-env)
```

> y para volver a la normalidad:

```bash
eval "$(minikube docker-env -u)"
```

**En Windows:**

```bash
 & minikube -p minikube docker-env | Invoke-Expression
```

> y para volver a la normalidad:

```bash
& minikube docker-env --unset | Invoke-Expression
```



---

### Limpiar ambiente

> ¡¡¡CUIDADO!!! Para evitar inconvenientes, es necesario borrar todos los deploys, services y pods anteriores.

```bash
kubectl delete deploy --all
kubectl delete service --all
kubectl delete pods --all
```

### Construcción de imágenes (v1 y v2)

> Creamos dos versiones de la aplicación con un cambio mínimo en el título (`snake-app/src/app/app.component.html`).

#### v1 (blue)

> Verificamos el HTML para v1-blue.

```html
<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v1 (blue)</span></h1>
```

> y construimos la imagen.

```bash
docker build -t snake-app:v1-blue .
```

#### v2 (green)

> Modificamos el HTML para v2-green.

```html
<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v2 (green)</span></h1>
```

> y construimos la imagen.

```bash
docker build -t snake-app:v2-green .
```

---

### Manifiestos de Kubernetes

Dentro de la carpeta `k8s/` se incluyen los archivos:

* `deployment-blue.yaml` → despliegue de **v1**
* `deployment-green.yaml` → despliegue de **v2**
* `service.yaml` → servicio expuesto para balancear entre ambas versiones

#### Aplicación de los manifiestos

```bash
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/deployment-green.yaml
kubectl apply -f k8s/service.yaml
```

#### Verificación de despliegues

```bash
kubectl get pods -l app=snake-app
kubectl rollout status deploy/snake-app-blue
kubectl rollout status deploy/snake-app-green
```

---

### Acceso a la aplicación

Abrir el servicio en navegador:

```bash
minikube service snake-app
```

---

### Cambiar entre versiones (Blue/Green)

- Pasar a **green**:

```bash
kubectl patch svc snake-app -p '{"spec":{"selector":{"app":"snake-app","color":"green"}}}'
```

- Pasar a **blue**:

```bash
kubectl patch svc snake-app -p '{"spec":{"selector":{"app":"snake-app","color":"blue"}}}'
```

⚠️ **Importante:**
La app está servida con Angular + Nginx, por lo que el navegador puede cachear el HTML.

Limpiar cache:
* En Safari de MacOS: `Option + Command + E`

O direcatamente forzar la recarga:
* En macOS: `Command + Shift + R`
* En Windows/Linux: `Ctrl + Shift + R`

---

### Validaciones útiles

- **Pods por color:**

```bash
kubectl get pods -l app=snake-app -L color
```

- **Ver endpoints del service y NodePort:**

```bash
kubectl get svc snake-app -o wide
```

- **Revisar logs:**

```bash
kubectl logs deploy/snake-app-blue
kubectl logs deploy/snake-app-green
```

---
