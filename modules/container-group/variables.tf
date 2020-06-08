variable container_group_name {
  type = string
  description = "The name of the container group to be deployed."
}

variable os_type {
  type = string
  description = "The OS type for the container group. Can be either Linux or Windows."
}

variable resource_group_name {
  type = string
  description = "The name of the resource group to deploy resources to."
}

variable location {
  type = string
  description = "The Azure region where resources will be deployed to."
}

variable ip_address_type {
  type = string
  description = "Indicates whether the group should be assigned a public or private IP address. If set to 'Private' then 'network_profile_id' must also be set."
  default = "Public"
}

variable dns_name_label {
  type = string
  description = "The DNS name for the container group."
  default = null
}

variable container_definitions {
  type = list(object({
    name = string
    image = string
    cpu = number
    memory = number
    ports = list(object({
      port = number
      protocol = string
    }))
    environment_variables = map(string)
    commands = list(string),
    volumes = list(object({
      name = string
      mount_path = string
      storage_account_name = string
      storage_account_key = string
      share_name = string
    }))
  }))
}