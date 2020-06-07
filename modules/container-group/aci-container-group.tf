resource azurerm_container_group container_group {
  name = var.container_group_name
  os_type = var.os_type
  resource_group_name = var.resource_group_name
  location = var.location
  ip_address_type = var.ip_address_type
  dns_name_label = var.dns_name_label
  
  dynamic "container" {
    for_each = var.container_definitions
    content {
      name = container.value["name"]
      image = container.value["image"]
      cpu = container.value["cpu"]
      memory = container.value["memory"]
      environment_variables = container.value["environment_variables"]
      
      dynamic "ports" {
        for_each = container.value.ports
        content {
          port = ports.value.port
          protocol = ports.value.protocol
        }
      }
    }
  }
}