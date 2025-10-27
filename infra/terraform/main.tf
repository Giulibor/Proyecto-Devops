# --- Red dedicada ---
resource "docker_network" "devnet" {
  name = var.network_name
  dynamic "labels" {
    for_each = local.labels
    iterator = kv
    content {
      label = kv.key
      value = kv.value
    }
  }
}

# --- Volúmenes para persistencia ---
resource "docker_volume" "notes_data" {
  name = "notes_data"
  dynamic "labels" {
    for_each = local.labels
    iterator = kv
    content {
      label = kv.key
      value = kv.value
    }
  }
}

# --- Imágenes ---

# 1) Nginx (pull público)
resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = true
}

# 2) notes-api (build local)
resource "docker_image" "notes_api" {
  name         = var.notes_image_tag
  keep_locally = true

  build {
    context    = var.notes_build_context
    dockerfile = var.notes_dockerfile
    # Puedes habilitar platforms si querés forzar multi-arch
    # platform = "linux/arm64"
  }
}

# 3) snake-app (build local)
resource "docker_image" "snake_app" {
  name         = var.snake_image_tag
  keep_locally = true

  build {
    context    = var.snake_build_context
    dockerfile = var.snake_dockerfile
    # platform = "linux/arm64"
  }
}

# --- Contenedores ---

# 1) Nginx demo
resource "docker_container" "nginx" {
  name  = var.nginx_container_name
  image = docker_image.nginx.image_id

  networks_advanced { name = docker_network.devnet.name }

  ports {
    internal = var.nginx_container_port
    external = var.nginx_host_port
    protocol = "tcp"
  }

  # Monta un index.html local dentro del contenedor
  mounts {
    type   = "bind"
    source = local.nginx_index_html
    target = "/usr/share/nginx/html/index.html"
  }

  # Healthcheck simple (wget viene en busybox/alpine)
  healthcheck {
    test         = ["CMD-SHELL", "wget -qO- http://localhost:${var.nginx_container_port} >/dev/null 2>&1 || exit 1"]
    interval     = "10s"
    timeout      = "2s"
    start_period = "5s"
    retries      = 5
  }

  restart = "unless-stopped"

  dynamic "labels" {
    for_each = local.labels
    iterator = kv
    content {
      label = kv.key
      value = kv.value
    }
  }
}

# 2) notes-api
resource "docker_container" "notes_api" {
  name  = var.notes_container_name
  image = docker_image.notes_api.image_id

  networks_advanced { name = docker_network.devnet.name }

  ports {
    internal = var.notes_container_port
    external = var.notes_host_port
    protocol = "tcp"
  }

  # Variables de entorno
  env = [for k, v in var.notes_env : "${k}=${v}"]

  # Volumen para datos
  mounts {
    type   = "volume"
    source = docker_volume.notes_data.name
    target = "/data"
  }

  # Ejemplo de healthcheck (dejado comentado por si tu imagen no trae curl/wget)
  # healthcheck {
  #   test         = ["CMD-SHELL", "wget -qO- http://localhost:${var.notes_container_port}/health >/dev/null 2>&1 || exit 1"]
  #   interval     = "10s"
  #   timeout      = "2s"
  #   start_period = "10s"
  #   retries      = 6
  # }

  restart = "unless-stopped"
  dynamic "labels" {
    for_each = local.labels
    iterator = kv
    content {
      label = kv.key
      value = kv.value
    }
  }

  depends_on = [docker_container.nginx]
}

# 3) snake-app (Angular u otra webapp)
resource "docker_container" "snake_app" {
  name  = var.snake_container_name
  image = docker_image.snake_app.image_id

  networks_advanced { name = docker_network.devnet.name }

  ports {
    internal = var.snake_container_port
    external = var.snake_host_port
    protocol = "tcp"
  }

  env = [for k, v in var.snake_env : "${k}=${v}"]

  # Healthcheck opcional (ajusta el endpoint real si existe)
  # healthcheck {
  #   test         = ["CMD-SHELL", "wget -qO- http://localhost:${var.snake_container_port} >/dev/null 2>&1 || exit 1"]
  #   interval     = "10s"
  #   timeout      = "2s"
  #   start_period = "15s"
  #   retries      = 6
  # }

  restart = "unless-stopped"
  dynamic "labels" {
    for_each = local.labels
    iterator = kv
    content {
      label = kv.key
      value = kv.value
    }
  }

  depends_on = [docker_container.nginx, docker_container.notes_api]
}
