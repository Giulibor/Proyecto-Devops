# Publicar una imagen Docker en GitHub Container Registry (GHCR)

Este procedimiento describe cómo autenticarse, etiquetar y subir imágenes Docker a **GitHub Container Registry (GHCR)**, manteniendo **tags inmutables** y visibilidad pública para reproducibilidad.

---

## 1. Generar un token de acceso en GitHub

1. Ingresar a
   👉 [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Clic en **Generate new token (classic)**.
3. Asignar un nombre (por ejemplo: `ghcr-access`).
4. Seleccionar los siguientes **scopes**:

   * `write:packages`
   * `read:packages`
   * `delete:packages` *(opcional)*
5. Clic en **Generate token** y copiar el valor generado.

   > ⚠️ Guardar el token: no se podrá volver a ver.

---

## 2. Iniciar sesión en GHCR desde Docker

```bash
export GH_USER=<github_user>
export GH_TOKEN=<github_token>
echo $GH_TOKEN | docker login ghcr.io -u $GH_USER --password-stdin
```

Salida esperada:

```
Login Succeeded
```

---

## 3. Etiquetar la imagen

Ejemplo con versión `0.1.0`:

```bash
export VERSION=0.1.0
docker tag traveltrack-api:$VERSION ghcr.io/$GH_USER/traveltrack-api:$VERSION
```

---

## 4. Subir la imagen

```bash
docker push ghcr.io/$GH_USER/traveltrack-api:$VERSION
```

Esto publicará la imagen en:

```
https://github.com/users/<github_user>/packages/container/package/traveltrack-api
```

---

## 5. Hacer pública la imagen (importante para evaluación)

1. Ir al enlace del package.
2. En la esquina superior derecha → **Package settings**.
3. En la sección **Danger Zone**, cambiar la visibilidad a **Public**.
4. Guardar los cambios.

---

## 6. Verificar la imagen

```bash
docker pull ghcr.io/$GH_USER/traveltrack-api:$VERSION
docker image inspect ghcr.io/$GH_USER/traveltrack-api:$VERSION | grep -i digest
```

---

## 7. Actualizar Helm / values.yaml

```yaml
image:
  repository: "ghcr.io/<github_user>/traveltrack-api"
  tag: "0.1.0"
  pullPolicy: IfNotPresent

config:
  appVersion: "0.1.0"
  port: 8080
```

---
