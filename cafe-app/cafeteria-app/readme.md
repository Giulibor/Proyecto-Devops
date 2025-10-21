# ☕ Cafeteria App — Guía de despliegue y pruebas

Aplicación **Spring Boot (Java 21 + Gradle)** desplegada en **Minikube (Kubernetes)** con **PostgreSQL**, **Prometheus** y **Grafana** para observabilidad.

---

## 🚀 Levantar toda la aplicación

### Desde la raiz del proyecto y con la terminal ejecutar:

```bash
./scripts/01_up.sh
```

#### Este script:

- Inicia Minikube y configura Docker.
- Construye la imagen cafeteria-app:latest.
- Despliega la app, la base de datos y los recursos de monitoreo.
- Instala automáticamente Helm y kube-prometheus-stack si faltan.
- Abre un túnel local con la aplicación en el navegador.

Cuando termine, la aplicación queda accesible desde una URL como:
```
http://127.0.0.1:<puerto_generado>
```

## 📊 Abrir Prometheus y Grafana
```bash
./scripts/02_ports.sh
```

Esto abre:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

El script muestra las credenciales de acceso (admin / contraseña auto-generada).

## 🧪 Pruebas de la API
### Crear una orden
```
curl -s -X POST "http://127.0.0.1:<puerto>/api/orders" \
  -H "Content-Type: application/json" \
  -d '{ "customerName": "Ana", "drink": "LATTE", "quantity": 2 }' | jq .
```
### Listar órdenes
```
curl -s "http://127.0.0.1:<puerto>/api/orders" | jq .
```
### Marcar una orden como entregada
```
curl -s -X POST "http://127.0.0.1:<puerto>/api/orders/1/deliver" | jq .
```
### Verificar estado y métricas
```
curl -s "http://127.0.0.1:<puerto>/actuator/health" | jq .
curl -s "http://127.0.0.1:<puerto>/actuator/prometheus" | head
```
# 🔍 Consultas y verificación de la consigna (demo)

## Tráfico HTTP
```
sum(rate(http_server_requests_seconds_count[5m])) by (uri, status)
```
## Órdenes creadas
```
rate(coffee_orders_created_total[5m])
```
## Regla de alerta activa
```
sum(increase(coffee_orders_created_total[5m])) by (drink)
```
## Memoria JVM:
```
jvm_memory_used_bytes{namespace="cafeteria", area="heap"}
```
### Para disparar una alerta, generar muchas órdenes seguidas:
```
for i in $(seq 1 50); do
  curl -s -X POST "http://127.0.0.1:<puerto>/api/orders" \
    -H "Content-Type: application/json" \
    -d '{ "customerName":"demo","drink":"LATTE","quantity":1 }' >/dev/null
done
```
# 🧹 Finalizar el entorno
```
./scripts/03_down.sh
```