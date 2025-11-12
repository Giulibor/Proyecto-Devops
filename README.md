# Proyecto DevOps
![EzHVMUaW8AUTY65](https://github.com/user-attachments/assets/e8936e8c-da13-42af-8b9d-3dcec3259c95)


---

## Estructura del repositorio

Actualmente el repositorio cuenta con las siguientes carpetas:

- **`snake-app/`**  
  Aplicación oficial del proyecto.  
  Aquí se encuentra el código de la aplicación **principal** desarrollada durante el curso.

- **`note-api/`**  
  API de notas utilizada para **pruebas en clase** y experimentación con conceptos de contenedores y Kubernetes.  

Se seguirán **agregando nuevas carpetas** a medida que el curso avance, cada una correspondiente a distintos módulos, prácticas o entregables.

---

## Documentación

En la carpeta `/docs/` se encuentran documentos de referencia, como convenciones de ramas, estrategias de branching, entre otros.  

---




⸻


# Proyecto DevOps
![EzHVMUaW8AUTY65](https://github.com/user-attachments/assets/e8936e8c-da13-42af-8b9d-3dcec3259c95)


Repositorio principal de prácticas y proyectos desarrollados para la materia **DevOps** en la **Universidad Católica del Uruguay (UCU)**.  

---

## Participantes del grupo

- **Giuliana Bordon**
- **Ricardo Castro**
- **Leonardo Conde**

---

## Repositorios relacionados

- **Repositorio oficial (este):** [Giulibor/Proyecto-Devops](https://github.com/Giulibor/Proyecto-Devops)  
- **Repositorio de pruebas:** [CocoCondo/snakeDevOps](https://github.com/CocoCondo/snakeDevOps/branches)

El repositorio de pruebas fue utilizado para ensayos, experimentos y validaciones previas, mientras que este repositorio se considera el **punto de referencia principal** del proyecto.

---

## Visión general

Este repositorio tiene como objetivo **albergar múltiples mini-proyectos DevOps**, siendo **`snake-app`** el principal.  
El resto de carpetas corresponde a ejercicios y demos que abordan distintas tecnologías del ecosistema DevOps: infraestructura como código, CI/CD, seguridad, observabilidad y Kubernetes avanzado.

---

## Estructura del repositorio

	snake-app/        → Aplicación principal (Angular)
	traveltrack-api/  → API de ejemplo (Node + TypeScript)
	notes-api/        → API de pruebas (FastAPI / Python)
	cafe-app/         → Microservicio Java (Spring Boot + Prometheus/Grafana)
	infra/            → Terraform, scripts de infraestructura o despliegue
	docs/             → Documentación técnica y convenciones del curso
	scripts/, reports → Archivos de soporte y automatización

Cada subproyecto contiene su propio `README.md` con instrucciones detalladas para instalación, ejecución y pruebas.

---

## Subproyectos principales

| Proyecto | Descripción | Stack / Enfoque | Documentación |
|-----------|--------------|------------------|----------------|
| **snake-app** | Proyecto principal del curso. | Angular + Docker + CI/CD | [`snake-app/README.md`](snake-app/README.md) |
| **traveltrack-api** | API de ejemplo para prácticas de despliegue y configuración. | Node.js + TypeScript + Express | [`traveltrack-api/README.md`](traveltrack-api/README.md) |
| **notes-api** | API de pruebas para contenedorización. | Python + FastAPI + Uvicorn | [`notes-api/README.md`](notes-api/README.md) |
| **cafe-app** | Microservicio Java con monitoreo. | Spring Boot + K8s + Prometheus/Grafana | [`cafe-app/README.md`](cafe-app/README.md) |

