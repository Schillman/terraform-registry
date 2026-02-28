variable "name" {
  type        = string
  description = "Sets the name of the project which will be used naming the main component in the module"
}

variable "docker_image_name" {
  type        = string
  description = "The name of the Docker image, including any tags or SHA256 repo digests."

}

variable "command" {
  type        = list(string)
  description = <<-DESC
    The command to use to start the container.
    Example: To run /usr/bin/myprogram -f baz.conf set the command to be ["/usr/bin/myprogram","-f","baz.con"].
    DESC
  default     = null
}

variable "environment_variables" {
  type        = list(string)
  description = "Environment variables to set in the form of KEY=VALUE pairs"
  default     = null
}

variable "devices" {
  type = list(object({
    host_path      = string                  # The path on the host where the device is located.
    container_path = optional(string, 0)     # The path in the container where the device will be bound.
    permissions    = optional(string, "rwm") # The cgroup permissions given to the container to access the device. Defaults to rwm.
  }))
  description = "Bind devices to the container."
  default     = []
}

variable "gpus" {
  type        = string
  description = "GPU devices to add to the container. Currently, only the value all is supported. Passing any other value will result in unexpected behavior."
  default     = null
}

variable "healthcheck" {
  type = list(object({
    test         = list(string)
    interval     = optional(string, 0) # Time between running the check (ms|s|m|h). Defaults to 0s.
    retries      = optional(number, 0) # Consecutive failures needed to report unhealthy. Defaults to 0.
    start_period = optional(string, 0) # Start period for the container to initialize before counting retries towards unstable (ms|s|m|h). Defaults to 0s.
    timeout      = optional(string, 0) # Maximum time to allow one check to run (ms|s|m|h). Defaults to 0s
  }))
  description = "A test to perform to check that the container is healthy."
  default     = []
}

variable "network_mode" {
  type        = string
  description = "Network mode of the container."
  default     = "host"
}

variable "ports" {
  description = "Publish a container's port(s) to the host."
  type = list(object({
    internal = number                      # Port within the container.
    external = number                      # Port exposed out of the container.
    ip       = optional(string, "0.0.0.0") # IP address/mask that can access this port. Defaults to 0.0.0.0.
    protocol = optional(string, "tcp")     # Protocol that can be used over this port. Defaults to tcp.
  }))
  default = []
}

variable "restart" {
  type        = string
  description = "The restart policy for the container. Must be one of 'no', 'on-failure', 'always', 'unless-stopped'. Defaults to unless-stopped."
  default     = "unless-stopped"
}

variable "runtime" {
  type        = string
  description = "Runtime to use for the container."
  default     = null
}

variable "volumes" {
  type = map(object({
    name           = string                    # The name of the Docker volume (will be generated if not provided).
    container_path = string                    # The path in the container where the volume will be mounted.
    from_container = optional(string)          # The container where the volume is coming from.
    host_path      = optional(string)          # The path on the host where the volume is coming from.
    volume_name    = optional(string)          # The name of the docker volume which should be mounted.
    read_only      = optional(bool, false)     # If true, this volume will be readonly. Defaults to false.
    driver         = optional(string, "local") # Driver type for the volume. Defaults to local.
    driver_opts    = optional(map(string))     # Options specific to the driver.
    labels = optional(list(object({            # User-defined key/value metadata (see below for nested schema)
      label = string                           # Name of the label
      value = string                           # Value of the label
    })), [])
  }))
  description = "Creates and mounts a volume in Docker to a container. This is used alongside docker_container to prepare volumes that can be shared across containers."
  default     = {}
}
