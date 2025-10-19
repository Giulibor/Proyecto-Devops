# Generar ordenes con el objetivo que se generen datos para monitoreo.

## Setear la URL de la APP

BASE='http://127.0.0.1:62912'

## Crear 2 productos

``` bash
curl -X POST '$BASE/api/products' \
  -H 'Content-Type: application/json' \
  -d '{"name":"espresso","price":120}'
```

``` bash
curl -X POST '$BASE/api/products' \
  -H 'Content-Type: application/json' \
  -d '{"name":"latte","price":180}'
```

## Listar para ver los IDs asignados (normalmente arrancan en 1, 2…)

``` bash
curl '$BASE/api/products' | jq .
```

## Una orden simple de 1 espresso (productId=1)

``` bash
curl -X POST '$BASE/api/orders' \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"productId":1,"quantity":1}]}'
```

## Ver las órdenes creadas

``` bash
curl '$BASE/api/orders' | jq .
```

## La regla es: sum(increase(orders_total[5m])) by (product) > 10 durante 1 min.
## Generá ~20 órdenes del mismo producto (p. ej. espresso con productId=1):

``` bash
for i in $(seq 1 20); do
  curl -X POST '$BASE/api/orders' \
    -H 'Content-Type: application/json' \
    -d '{"items":[{"productId":1,"quantity":1}]}' > /dev/null
done
```

# Revisar datos en Grafana

