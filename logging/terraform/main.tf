resource azurerm_resource_group resource_group {
  name = "jef-aci-logging-test"
  location = "eastus2"
}

module aci_container_group {
  providers = {
    azurerm = azurerm
  }

  source = "../../modules/container-group"
  container_group_name = azurerm_resource_group.resource_group.name
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  dns_name_label = azurerm_resource_group.resource_group.name
  os_type = "Linux"

  container_definitions = [
    {
      name = "nginx"
      image = "nginx:latest"
      cpu = 0.5
      memory = 0.5
      ports = [
        {
          port = 80
          protocol = "TCP"
        }
      ]
      environment_variables = {}
    }
  ]

  
}