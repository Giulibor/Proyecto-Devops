# PromQL para la demo
## RPS total (5m)
sum(rate(http_server_requests_seconds_count{namespace="cafeteria"}[5m]))

## RPS por endpoint y método
sum(rate(http_server_requests_seconds_count{namespace="cafeteria"}[5m])) by (uri, method, status)

## Latencia promedio por endpoint
sum(rate(http_server_requests_seconds_sum{namespace="cafeteria"}[5m])) 
/ 
sum(rate(http_server_requests_seconds_count{namespace="cafeteria"}[5m]))

## P95
histogram_quantile(0.95,
  sum(rate(http_server_requests_seconds_bucket{namespace="cafeteria"}[5m])) by (le)
)

## Pedidos creados/entregados (contadores de negocio):
increase(coffee_orders_created_total{namespace="cafeteria"}[5m])
increase(coffee_orders_delivered_total{namespace="cafeteria"}[5m])

## Memoria JVM:
jvm_memory_used_bytes{namespace="cafeteria", area="heap"}
