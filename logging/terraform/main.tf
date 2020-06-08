resource azurerm_resource_group resource_group {
  name = "jef-aci-logging-test"
  location = "eastus2"
}

resource azurerm_storage_account storage_account {
  name = replace(azurerm_resource_group.resource_group.name,"-","")
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  account_kind = "StorageV2"
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource azurerm_storage_share share {
  name = "logs"
  storage_account_name = azurerm_storage_account.storage_account.name
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
      cpu = 0.25
      memory = 0.5
      ports = [
        {
          port = 80
          protocol = "TCP"
        }
      ]
      environment_variables = null
      commands = null,
      volumes = [
        {
          name = "logs"
          mount_path = "/var/log/nginx"
          storage_account_name = azurerm_storage_account.storage_account.name
          storage_account_key = azurerm_storage_account.storage_account.primary_access_key
          share_name = azurerm_storage_share.share.name
        }
      ]
    },
    {
      name = "filebeat"
      image = "docker.elastic.co/beats/filebeat:7.7.1"
      cpu = 0.25
      memory = 0.5
      commands = [
        "filebeat",
        "-E",
        "output.console.enabled=true",
        "-E",
        "output.elasticsearch.enabled=false",
        "-e",
        "-M", 
        "nginx.access.var.paths=[/var/log/nginx/access*.log]",
        "--modules",
        "nginx"
      ]
      environment_variables = null
      ports = [],
      volumes = [
        {
          name = "logs2"
          mount_path = "/var/log/nginx"
          storage_account_name = azurerm_storage_account.storage_account.name
          storage_account_key = azurerm_storage_account.storage_account.primary_access_key
          share_name = azurerm_storage_share.share.name
        }
      ]
    }
  ]

  
}