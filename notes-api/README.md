# Notes API (FastAPI + Docker)

API mínima para gestionar notas, desarrollada en **Python (FastAPI)** y contenerizada con **Docker**.  
Este servicio forma parte del repositorio académico [Proyecto-Devops](https://github.com/Giulibor/Proyecto-Devops).

## 📌 Funcionalidades

- **GET /** → mensaje confirmando que la API está activa.  
- **POST /add** → permite agregar una nota con `title` y `content`.  
- **GET /list** → devuelve todas las notas creadas.  

Las notas se persisten en `data/notes.json` (mediante un volumen de Docker).

---

## 🗂️ Estructura del proyecto

```text
note-api/
├─ main.py              # Código principal FastAPI
├─ requirements.txt     # Dependencias
├─ Dockerfile           # Imagen de la aplicación
└─ data/                # Carpeta montada como volumen
    └─ notes.json       # Archivo persistente (se crea automáticamente)
````

---

## ⚙️ Requisitos

- Python 3.12+
- Docker
- Entorno virtual (opcional, para pruebas locales)

---

## ▶️ Ejecución local

```bash
# Limpiar entorno virtual
rm -rf .venv

# Crear y activar entorno virtual
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Levantar la API
uvicorn main:app --reload
```

Acceso a swagger: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 🐳 Ejecución con Docker

### 1. Construir imagen

```bash
docker build -t notes-api .
```

### 2. Ejecutar contenedor con volumen

```bash
# Crear carpeta de datos en el host
mkdir -p data

# Levantar contenedor
docker run -p 8000:8000 -v $(pwd)/data:/app/data --name notes1 notes-api
```

---

## 🔎 Pruebas

* **Agregar nota**

```bash
curl -X POST http://localhost:8000/add \
-H "Content-Type: application/json" \
-d '{"title":"Primera nota","content":"Probando persistencia"}'
```

* **Listar notas**

```bash
curl http://localhost:8000/list
```

* **Ver archivo persistido en el host**

```bash
cat data/notes.json
```

---

## 🧹 Resetear entorno

Esta sección explica cómo dejar el entorno en cero eliminando contenedores, imágenes y volúmenes de Docker relacionados al proyecto.

```bash
# Detener y eliminar el contenedor
docker stop notes1 && docker rm notes1

# Eliminar la imagen
docker rmi notes-api

# Limpiar las notas persistidas en el host
rm -rf data/
```
