# --- Nombres y red ---
variable "network_name" {
  type        = string
  description = "Nombre de la red Docker dedicada"
  default     = "devnet"
}

variable "nginx_container_name" {
  type        = string
  default     = "tf-nginx"
}

variable "notes_container_name" {
  type        = string
  default     = "notes-api"
}

variable "snake_container_name" {
  type        = string
  default     = "snake-app"
}

# --- Imágenes ---
variable "nginx_image" {
  type        = string
  default     = "nginx:alpine"
}

# Build local (tags resultantes)
variable "notes_image_tag" {
  type        = string
  default     = "notes-api:dev"
}

variable "snake_image_tag" {
  type        = string
  default     = "snake-app:dev"
}

# Contextos/rutas de build (relativos a la raíz del repo)
variable "notes_build_context" {
  type        = string
  default     = "../../notes-api"
}

variable "notes_dockerfile" {
  type        = string
  default     = "Dockerfile"
}

variable "snake_build_context" {
  type        = string
  default     = "../../snake-app"
}

variable "snake_dockerfile" {
  type        = string
  default     = "Dockerfile"
}

# --- Puertos host -> contenedor ---
# nginx: 8080 -> 80
variable "nginx_host_port" {
  type        = number
  default     = 8080
}

variable "nginx_container_port" {
  type        = number
  default     = 80
}

# notes-api: 8081 -> 8080
variable "notes_host_port" {
  type        = number
  default     = 8081
}

variable "notes_container_port" {
  type        = number
  default     = 8000
}

# snake-app: 8082 -> 8080 (ajusta si tu contenedor escucha en otro)
variable "snake_host_port" {
  type        = number
  default     = 8082
}

variable "snake_container_port" {
  type        = number
  default     = 80
}

# --- Variables de entorno opcionales ---
variable "notes_env" {
  type        = map(string)
  description = "Variables de entorno para notes-api"
  default = {
    NOTES_DB_PATH = "/data/notes.json"
    APP_ENV       = "dev"
  }
}

variable "snake_env" {
  type        = map(string)
  description = "Variables de entorno para snake-app"
  default = {
    APP_ENV = "dev"
  }
}