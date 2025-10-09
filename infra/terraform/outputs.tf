output "nginx_url" {
  value       = "http://localhost:${var.nginx_host_port}"
  description = "URL de Nginx"
}

output "notes_api_url" {
  value       = "http://localhost:${var.notes_host_port}/docs"
  description = "URL de notes-api Swagger UI"
}

output "snake_app_url" {
  value       = "http://localhost:${var.snake_host_port}"
  description = "URL de snake-app"
}