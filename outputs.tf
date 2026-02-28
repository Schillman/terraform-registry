output "container_id" {
  description = "The ID of the Docker container."
  value       = docker_container.main.id
}

output "container_name" {
  description = "The name of the Docker container."
  value       = docker_container.main.name
}

output "image_id" {
  description = "The ID of the Docker image used by the container."
  value       = docker_image.main.image_id
}
