variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "virtual_network_name" {
  description = "Name of your Azure Virtual Network"
  default     = ""
}

variable "virtual_network_address_space" {
  description = "The address space to be used for the Azure virtual network."
  default     = []
}

variable "route_table_name" {
  description = "The route table name"
  default     = ""
}

variable "storage_account_id" {
  description = "The ID of the storage account."
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Specifies the id of the Log Analytics Workspace"
  default     = ""
}

variable "azure_monitor_logs_retention_in_days" {
  description = "The Azure Monitoring data retention in days."
  default     = 30
}
