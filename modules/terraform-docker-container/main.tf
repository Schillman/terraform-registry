resource "docker_image" "main" {
  name = var.docker_image_name
}

resource "docker_volume" "volumes" {
  for_each = var.volumes

  name        = each.value.name
  driver      = each.value.driver
  driver_opts = each.value.driver_opts

  dynamic "labels" {
    for_each = each.value.labels
    content {
      label = labels.value.label
      value = labels.value.value
    }
  }
}

resource "docker_container" "main" {
  image        = docker_image.main.image_id
  name         = var.name
  command      = var.command
  env          = var.environment_variables
  gpus         = var.gpus
  restart      = var.restart
  runtime      = var.runtime
  network_mode = var.network_mode
  dynamic "healthcheck" {
    for_each = var.healthcheck

    content {
      test         = healthcheck.value.test
      interval     = healthcheck.value.interval
      retries      = healthcheck.value.retries
      start_period = healthcheck.value.start_period
      timeout      = healthcheck.value.timeout
    }
  }
  dynamic "devices" {
    for_each = var.devices

    content {
      container_path = devices.value.container_path
      host_path      = devices.value.host_path
      permissions    = devices.value.permissions
    }
  }
  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      ip       = ports.value.ip
      protocol = ports.value.protocol
    }
  }

  dynamic "volumes" {
    for_each = var.volumes
    content {
      volume_name    = volumes.value.name
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
      from_container = volumes.value.from_container
      host_path      = volumes.value.host_path
    }
  }
}
