variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "project_name" {
  description = "The name of the project."
  default     = ""
}

variable "subscription_type" {
  description = "Summary description of the purpose of the subscription that contains the resource. Often broken down by deployment environment type or specific workloads"
  default     = ""
}

variable "environment" {
  description = "The stage of the development lifecycle for the workload that the resource supports"
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


variable "firewall_service_endpoints" {
  description = "Service endpoints to add to the firewall subnet"
  type        = list(string)
  default = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.AzureCosmosDB",
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}

variable "public_ip_names" {
  description = "Public ips is a list of ip names that are connected to the firewall. At least one is required."
  type        = list(string)
  default     = ["fw-public"]
}

variable "firewall_zones" {
  description = "A collection of availability zones to spread the Firewall over"
  type        = list(string)
  default     = null
}

variable "firewall_application_rules" {
  description = "List of application rules to apply to firewall."
  type        = list(object({ name = string, action = string, source_addresses = list(string), target_fqdns = list(string), protocol = object({ type = string, port = string }) }))
  default     = []
}

variable "firewall_network_rules" {
  description = "List of network rules to apply to firewall."
  type        = list(object({ name = string, action = string, source_addresses = list(string), destination_ports = list(string), destination_addresses = list(string), protocols = list(string) }))
  default     = []
}

variable "firewall_nat_rules" {
  description = "List of nat rules to apply to firewall."
  type        = list(object({ name = string, action = string, source_addresses = list(string), destination_ports = list(string), destination_addresses = list(string), protocols = list(string), translated_address = string, translated_port = string }))
  default     = []
}

variable "fw_pip_diag_logs" {
  description = "Firewall Public IP Monitoring Category details for Azure Diagnostic setting"
  default     = ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports"]
}

variable "fw_diag_logs" {
  description = "Firewall Monitoring Category details for Azure Diagnostic setting"
  default     = ["AzureFirewallApplicationRule", "AzureFirewallNetworkRule"]
}

variable "storage_account_id" {
  description = "The ID of the storage account."
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Specifies the id of the Log Analytics Workspace"
  default     = ""
}

variable "log_analytics_logs_retention_in_days" {
  description = "The log analytics workspace data retention in days. Possible values range between 30 and 730."
  default     = 30
}

variable "azure_monitor_logs_retention_in_days" {
  description = "The Azure Monitoring data retention in days."
  default     = 30
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
