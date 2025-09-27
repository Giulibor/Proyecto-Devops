
# Proyecto-Devops

> ⚠️ **Nota:** Debido a la reestructuración del repositorio, **todos los comandos deben ejecutarse desde dentro del directorio `snake-app`**.

## Entrega 1

Contiene un ejemplo práctico de despliegue **Blue/Green** en Kubernetes utilizando **Minikube** y **Docker** como entorno local.
La aplicación base es una versión simple del juego Snake en Angular.

---

### Arranque de Minikube

```bash
minikube start --driver=docker
```

> Inicia un clúster local de Kubernetes con Minikube, utilizando Docker como proveedor de máquinas virtuales.

```bash
eval $(minikube docker-env)
```

```bash
 & minikube -p minikube docker-env | Invoke-Expression
```

> Para volver a la normalidad:

```bash
& minikube docker-env --unset | Invoke-Expression
```

> Configura tu Docker local para que use el demonio de Docker interno de Minikube.

---

### Limpiar ambiente ¡ATENCION!

¡¡¡CUIDADO!!! Acorde necesario, borrar todos los deploys, services y pods anteriores

```bash
kubectl delete deploy --all
kubectl delete service --all
kubectl delete pods --all
```

### Construcción de imágenes (v1 y v2)

Creamos dos versiones de la aplicación con un cambio mínimo en el título (`snake-app/src/app/app.component.html`).

#### v1 (blue)

```html
<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v1 (blue)</span></h1>
```

```bash
docker build -t snake-app:v1-blue .
```

#### v2 (green)

```html
<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v2 (green)</span></h1>
```

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

* Pasar a **green**:

```bash
kubectl patch svc snake-app -p '{"spec":{"selector":{"app":"snake-app","color":"green"}}}'
```

* Pasar a **blue**:

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

* **Pods por color:**

```bash
kubectl get pods -l app=snake-app -L color
```

* **Ver endpoints del service y NodePort:**

```bash
kubectl get svc snake-app -o wide
```

* **Revisar logs:**

```bash
kubectl logs deploy/snake-app-blue
kubectl logs deploy/snake-app-green
```

---
