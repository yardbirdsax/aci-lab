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

resource azurerm_eventhub_namespace eventhub_namespace {
  name = azurerm_resource_group.resource_group.name
  resource_group_name = azurerm_resource_group.resource_group.name
  sku = "Standard"
  location = azurerm_resource_group.resource_group.location
}

resource azurerm_eventhub eventhub {
  name = "logs"
  namespace_name = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
  message_retention = 1
  partition_count = 1
}

resource azurerm_eventhub_authorization_rule eventhub_auth {
  name = "log_sender"
  eventhub_name = azurerm_eventhub.eventhub.name
  namespace_name = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
  send = true
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
        "output.kafka.enabled=true",
        "-E",
        "output.kafka.hosts=[${azurerm_eventhub_namespace.eventhub_namespace.name}.servicebus.windows.net:9093]",
        "-E",
        "output.kafka.topic=logs",
        "-E",
        "output.kafka.version=2.0.0",
        "-E",
        "output.kafka.ssl.enabled=true",
        "-E",
        "output.kafka.username=$ConnectionString",
        "-E",
        "output.kafka.password=${azurerm_eventhub_authorization_rule.eventhub_auth.primary_connection_string}",
        "-E",
        "output.kafka.compression=none",
        # "-E",
        # "output.console.enabled=true",
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

output aci_dns_name {
  value = module.aci_container_group.aci_dns_name
}

output aci_ip_address {
  value = module.aci_container_group.aci_ip_address
}