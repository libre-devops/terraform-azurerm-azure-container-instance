variable "container_instance_name" {
  type        = string
  description = "The name of the container instance"
}

variable "dns_name_label" {
  type        = string
  description = "The name of a DNS label if used"
  default     = null
}

variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM."
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine."
  type        = string
  default     = ""
}

variable "ip_address_type" {
  type        = string
  description = "What the ip address type is if used"
  default     = null
}

variable "key_vault_key_id" {
  type        = string
  description = "If a CMK is used, the key ID used to encrypt the instances"
  default     = null
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "network_profile_name" {
  type        = string
  description = "If a private network is used, the name of that network profile."
  default     = null
}

variable "os_type" {
  type        = string
  description = "The OS type for the container instance"
}

variable "restart_policy" {
  type        = string
  description = "The restart policy of the container, defaults to Always"
  default     = "Always"
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "settings" {
  description = "Specifies the Authentication enabled or not"
  default     = false
  type        = any
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "vnet_integration_enabled" {
  type        = bool
  description = "If vnet integration is enabled. can only be activated on a Linux container"
  default     = null
}
