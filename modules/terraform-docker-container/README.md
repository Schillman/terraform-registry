## Usage
```hcl
module "ubuntu" {
  source = "../.."

  name                  = format("server-%s", "tst")
  docker_image_name     = "ubuntu"
  network_mode          = "bridge"

  environment_variables = ["KEY1=VALUE1", "KEY2=VALUE2"]

  ports = [{
    internal = 22
    external = 22
  }]

  volumes = {
    "Files" = {
      name           = "Files"
      container_path = "/Files"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.0.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.0.2 |

## Resources

| Name | Type |
|------|------|
| [docker_container.main](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/container) | resource |
| [docker_image.main](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/image) | resource |
| [docker_volume.volumes](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_command"></a> [command](#input\_command) | The command to use to start the container.<br>Example: To run /usr/bin/myprogram -f baz.conf set the command to be ["/usr/bin/myprogram","-f","baz.con"]. | `list(string)` | `null` | no |
| <a name="input_devices"></a> [devices](#input\_devices) | Bind devices to the container. | <pre>list(object({<br>    host_path      = string                  # The path on the host where the device is located.<br>    container_path = optional(string, 0)     # The path in the container where the device will be bound.<br>    permissions    = optional(string, "rwm") # The cgroup permissions given to the container to access the device. Defaults to rwm.<br>  }))</pre> | `null` | no |
| <a name="input_docker_image_name"></a> [docker\_image\_name](#input\_docker\_image\_name) | The name of the Docker image, including any tags or SHA256 repo digests. | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables to set in the form of KEY=VALUE pairs | `list(string)` | `null` | no |
| <a name="input_gpus"></a> [gpus](#input\_gpus) | GPU devices to add to the container. Currently, only the value all is supported. Passing any other value will result in unexpected behavior. | `string` | `null` | no |
| <a name="input_healthcheck"></a> [healthcheck](#input\_healthcheck) | A test to perform to check that the container is healthy. | <pre>list(object({<br>    test         = list(string)<br>    interval     = optional(string, 0) # Time between running the check (ms|s|m|h). Defaults to 0s.<br>    retries      = optional(Number, 0) # Consecutive failures needed to report unhealthy. Defaults to 0.<br>    start_period = optional(string, 0) # Start period for the container to initialize before counting retries towards unstable (ms|s|m|h). Defaults to 0s.<br>    timeout      = optional(string, 0) # Maximum time to allow one check to run (ms|s|m|h). Defaults to 0s<br>  }))</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Sets the name of the project which will be used naming the main component in the module | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode of the container. | `string` | `"host"` | no |
| <a name="input_ports"></a> [ports](#input\_ports) | Publish a container's port(s) to the host. | <pre>list(object({<br>    internal = number                      # Port within the container.<br>    external = number                      # Port exposed out of the container.<br>    ip       = optional(string, "0.0.0.0") # IP address/mask that can access this port. Defaults to 0.0.0.0.<br>    protocol = optional(string, "tcp")     # Protocol that can be used over this port. Defaults to tcp.<br>  }))</pre> | `[]` | no |
| <a name="input_restart"></a> [restart](#input\_restart) | The restart policy for the container. Must be one of 'no', 'on-failure', 'always', 'unless-stopped'. Defaults to unless-stopped. | `string` | `"unless-stopped"` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime to use for the container. | `string` | `null` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Creates and mounts a volume in Docker to a container. This is used alongside docker\_container to prepare volumes that can be shared across containers. | <pre>map(object({<br>    name           = string                    # The name of the Docker volume (will be generated if not provided).<br>    container_path = string                    # The path in the container where the volume will be mounted.<br>    from_container = optional(string)          # The container where the volume is coming from.<br>    host_path      = optional(string)          # The path on the host where the volume is coming from.<br>    volume_name    = optional(string)          # The name of the docker volume which should be mounted.<br>    read_only      = optional(bool, false)     # If true, this volume will be readonly. Defaults to false.<br>    driver         = optional(string, "local") # Driver type for the volume. Defaults to local.<br>    driver_opts    = optional(map(string))     # Options specific to the driver.<br>    labels = optional(list(object({            # User-defined key/value metadata (see below for nested schema)<br>      label = string                           # Name of the label<br>      value = string                           # Value of the label<br>    })), [])<br>  }))</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->