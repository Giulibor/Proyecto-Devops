# Notes API (FastAPI) + Docker

API mínima para guardar notas con tres endpoints:

GET / → /: Mensjae indicandi que el API está activo

POST /add → agrega una nota con un texto (title, content)

GET /list → lista todas las notas creadas

Las notas se guardan en data/notes.json (persistencia mediante volumen).

## Contenido

- [General](#general)
    - [Requisitos](#1-requisitos)
    - [Estructura del proyceto](#estructura-del-proyecto)
- [API](#api)
    - [Código](#código)
    - [Pruebas locales](#pruebas-locales)
- [Docker](#docker)
    - [Imagen Docker](#1-imagen-docker)
    - [Comandos de prueba](#2-comandos-de-prueba)
        - [Agregar nota](#agregar-nota)
        - [Listar notas](#listar-notas-get-list)
        - [Visualizar archivo persistente en host](#ver-el-archivo-persistido-en-el-host)
- [Resumen entrega](#resumen-entrega)


## General

### 1. Requisitos
- Python 3.12+
- Docker
- Entorno virtual

### 2. Estructura del proyecto
```text
ApiDevOps/
├─ main.py
├─ requirements.txt
├─ Dockerfile
└─ data/   # carpeta montada como volumen (persistencia)
    └─ notes.json  # se crea automáticamente la primera vez
```
Si data/ no existe, crearla con mkdir data.

## API
### 1. Código
- Código general en main.py 
- Lista de requerimientos en requirements.txt

### 2. Pruebas locales

```text
# entorno virtual
python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload

```

## Docker
### 1. Imagen Docker
- Código fuente en archivo Dockerfile
- Build de la imagen :
    ```text
    docker build -t notes-api .
    ```
- Ejecutar contenedor con volumen
    ```text
    # Asegurate de tener la carpeta de datos en el host
        mkdir -p data

    # Levantar el contenedor mapeando el volumen
        docker run -p 8000:8000 -v $(pwd)/data:/app/data --name notes1 notes-api
    ```

### 2. Comandos de prueba

#### Agregar nota:
```text   
    curl -X POST http://localhost:8000/add \
    -H "Content-Type: application/json" \
    -d '{"title":"Primera nota","content":"Probando persistencia"}'
```

Respuesta esperada: ```text {"message":"Note 'Primera nota' added!"} ```
<br>


#### Listar notas (GET /list):
```text
    curl http://localhost:8000/list
```

#### Ver el archivo persistido en el host
```text
    cat data/notes.json
```

## Resumen entrega 
```text
Build: docker build -t notes-api .

Run: 
docker run -p 8000:8000 -v $(pwd)/data:/app/data --name notes1 notes-api

Probar:
    - GET /
    - POST /add 
        (con JSON { "title": "...", "content": "..." })
    - GET /list

Persistencia: datos en ./data/notes.json del host.
```