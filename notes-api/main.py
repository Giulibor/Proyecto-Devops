from fastapi import FastAPI
from pydantic import BaseModel
import json
import os

app = FastAPI()

NOTES_FILE = "data/notes.json"

# Crear el archivo si no existe
if not os.path.exists(NOTES_FILE):
    with open(NOTES_FILE, "w") as f:
        json.dump([], f)


def load_notes():
    with open(NOTES_FILE, "r") as f:
        return json.load(f)


def save_notes(notes):
    with open(NOTES_FILE, "w") as f:
        json.dump(notes, f)


# Modelo de entrada para agregar notas
class Note(BaseModel):
    title: str
    content: str


@app.get("/")
def read_root():
    message = os.getenv("API_TITLE", "API running")
    return {"message": message}


@app.post("/add")
def add_note(note: Note):
    notes = load_notes()
    notes.append({"title": note.title, "content": note.content})
    save_notes(notes)
    return {"message": f"Note '{note.title}' added!"}


@app.get("/list")
def list_notes():
    notes = load_notes()
    return {"notes": notes}