# Generar ordenes con el objetivo que se generen datos para monitoreo.

## Setear la URL de la APP

BASE='http://127.0.0.1:53107'

## Crear órdenes de ejemplo (lab: solo órdenes)

``` bash
curl -X POST "$BASE/api/orders" \
  -H 'Content-Type: application/json' \
  -d '{"customerName":"Ana","drink":"latte","quantity":2}'
```

``` bash
curl -X POST "$BASE/api/orders" \
  -H 'Content-Type: application/json' \
  -d '{"customerName":"Bruno","drink":"espresso","quantity":1}'
```

## Ver las órdenes creadas

``` bash
curl "$BASE/api/orders" | jq .
```

## La regla es: sum(increase(coffee_orders_created_total[5m])) by (product) > 10 durante 1 min.
## Generá ~20 órdenes del mismo producto (p. ej. espresso con productId=1):

``` bash
for i in $(seq 1 20); do
  curl -X POST "$BASE/api/orders" \
    -H 'Content-Type: application/json' \
    -d '{"customerName":"LoadTest","drink":"latte","quantity":1}' > /dev/null
  sleep 2
done
```

## Ver métricas crudas (debug rápido)

``` bash
curl -s "$BASE/actuator/prometheus" | grep -E '^coffee_orders_(created|delivered)_total'
```

# Revisar datos en Grafana

1. Abrí Grafana (port-forward o URL que uses).
2. Navegá a **Dashboards → Browse → Carpeta “Cafeteria” → _Cafeteria – Orders & App_**.
3. En ese dashboard verás:
   - Órdenes por producto (últimos 5 minutos) – panel “Órdenes por producto (últimos 5m)”.
   - Requests HTTP por status (rate 5m).
   - JVM Heap used.
4. La alerta _HighOrderRate_ dispara cuando `sum(increase(coffee_orders_created_total[5m])) by (product) > 10` por 1 minuto.
