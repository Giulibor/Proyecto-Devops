## 📌 Propósito

El archivo `configmap.yml` define un ConfigMap y tres Deployments (A, B, C) para la aplicación Notes API. Cada Deployment utiliza una variable de entorno `API_TITLE` que obtiene su valor desde el ConfigMap, permitiendo identificar visualmente cada instancia con un título distinto. Esto facilita la gestión y diferenciación de las tres instancias de la Notes API en el clúster.

> **NOTA** Ejecutar comandos desde la raiz del repositorio.

## ⚙️ Aplicar configuración

Si aún no tienes un clúster local, inicia Minikube con:

```bash
minikube start --driver=docker
```

Construir y disponibilizar la imagen `notes-api:latest` para Minikube.
  
```bash
eval "$(minikube -p minikube docker-env)"
docker build -t notes-api:latest ./notes-api
```

Luego, aplica la configuración con el siguiente comando:

```bash
kubectl apply -f notes-api/configmap.yml
```

Luego, para verificar que los recursos se hayan creado correctamente, puedes listar todos los recursos con:

```bash
kubectl get all
```

## 🌐 Acceso a los Pods

Para acceder a las aplicaciones desplegadas, es necesario exponer los Pods mediante un Service. Puedes crear un Service para cada Deployment usando el siguiente comando:

```bash
kubectl expose deployment notes-api-a --type=NodePort --port=80 --name=service-notes-api-a
kubectl expose deployment notes-api-b --type=NodePort --port=80 --name=service-notes-api-b
kubectl expose deployment notes-api-c --type=NodePort --port=80 --name=service-notes-api-c
```

Esto creará un Service de tipo NodePort que expone el puerto 80 de cada Deployment.

## 🧪 Prueba

Para probar cada instancia localmente, puedes usar `kubectl port-forward` para redirigir un puerto local a un puerto del Pod. Por ejemplo:

```bash
kubectl port-forward deployment/notes-api-a 8081:8000
kubectl port-forward deployment/notes-api-b 8082:8000
kubectl port-forward deployment/notes-api-c 8083:8000
```

Luego, en otra terminal o desde tu navegador, realiza una petición `curl` a cada puerto para ver el título distintivo:

```bash
curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083
```

Cada respuesta debería mostrar el título correspondiente definido en el ConfigMap.

## 🧹 Limpieza

Para eliminar todos los recursos creados por este archivo, ejecuta:

```bash
kubectl delete -f notes-api/configmap.yml
kubectl delete deploy --all
kubectl delete service --all
kubectl delete pods --all
minikube image rm notes-api:latest
```

Apagar Minikube

```bash
minikube stop
```
