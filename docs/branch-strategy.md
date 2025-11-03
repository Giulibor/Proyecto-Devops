# Estrategia de ramas

* **`main` (estable/revisada)**
  Siempre la **última versión que verán/corregirán los profesores**. Solo se actualiza desde un PR de `pre-release` cuando el equipo decide “congelar” una entrega.

  * Protegida: no commits directos, 1–2 reviews

* **`pre-release`**
  Donde se **mergean todas las actualizaciones** (features, fixes). Es el “ staging ” del curso. Cuando está estable → PR a `main`.

* **Ramas de trabajo (de corta vida)**

  * `feature/<algo>` para nuevas funcionalidades
  * `fix/<algo>` para bugs
  * `refactor/<algo>` para reestructura (ej.: `refactor/restructure-project-folders`)
    Se crean desde `pre-release` y vuelven a `pre-release` por PR.

* **Hotfixes urgentes**
  Si encontrás un error crítico en lo ya entregado: `hotfix/<algo>` desde `main`, merge a `main` y back-merge a `pre-release`.

## Flujo recomendado

1. Commits + PR hacia `pre-release`

```bash
git push -u origin refactor/restructure-project-folders
# Abrir PR -> base: pre-release
```

2. Cuando `pre-release` está estable para entrega → **PR a `main`**

```bash
# En GitHub: abrir PR pre-release -> main
# Al mergear, crear tag:
git checkout main
git pull
git tag -a v0.3.0 -m "Entrega UT2 - revisión profesores"
git push origin v0.3.0
```

## Protecciones (GitHub)

* **`main`**

  * Require pull request + al menos 1 review.
  * Bloquear “force push” y commits directos.
  * Requerir que el branch esté actualizado con base antes de merge.

* **`pre-release`**

  * Un review.


## Convenciones de nombres (resumen)

* `feature/…`, `fix/…`, `refactor/…`, `hotfix/…`, `docs/…`, `chore/…`
* kebab-case: `feature/add-blue-green-deploy`
* ver documento /docs/branch-naming.md.

## Diagrama

```
feature/*      fix/*      refactor/*
     \            |            /
      \-----------v-----------/         hotfix/*
                  |                         \
             pre-release ------------------> main
                     \______________________^
                           (PR + tag)
```

## Estrategia específica del Laboratorio 3

Para el Laboratorio 3 se utiliza una estructura de ramas especial que facilita el desarrollo y la integración de las funcionalidades específicas del laboratorio:

* **`main`** (producción): rama estable que contiene la versión final y revisada del proyecto.
* **`pre-release`** (preproducción): rama donde se integran las funcionalidades de laboratorio y otras mejoras antes de pasar a producción.
* **`laboratorio3`**: rama base de desarrollo exclusiva para el Laboratorio 3, donde se integran las ramas individuales del laboratorio.
* Ramas de desarrollo específicas: `laboratorio3-xx-nombre`, donde `xx` es el número de la tarea o funcionalidad y `nombre` una breve descripción.

### Flujo de merges

Las ramas individuales de desarrollo (`laboratorio3-xx-nombre`) se mergean primero a la rama `laboratorio3`. Cuando `laboratorio3` está estable, se hace un merge a `pre-release`. Finalmente, cuando `pre-release` está listo, se realiza un merge a `main`.

### Diagrama

```
       main
        ▲
    pre-release
        ▲
   laboratorio3
     ▲       ▲
lab3-01   lab3-02
```
