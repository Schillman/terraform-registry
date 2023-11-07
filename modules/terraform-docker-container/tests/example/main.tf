terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
}


module "ubuntu" {
  source = "github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0"

  name              = format("server-%s", "tst")
  docker_image_name = "ubuntu"
  network_mode      = "bridge"

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
