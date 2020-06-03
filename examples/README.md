# Azure Firewall Terraform Module

This module create a firewall with application/NAT/Network rules also supports the Hub Virtual Network module to enable the firewall option.

## Module Usage

``` hcl
module "hub-firewall" {
  source = "github.com/tietoevry-infra-as-code/terraform-azurerm-caf-vnet-hub-firewall?ref=v1.0.0"

  # This module will not create a resource group, proivde the name of an existing resource group
  # location must be the resource group location
  # virtual network address space and name, route table name to be provided from vnet-hub module.  
  resource_group_name           = var.resource_group_name
  location                      = var.location
  virtual_network_name          = var.virtual_network_name
  virtual_network_address_space = var.virtual_network_address_space
  route_table_name              = var.route_table_name

  # (Required) Project_Name, Subscription_type and environment are must to create resource names.
  project_name      = "tieto-internal"
  subscription_type = "shared"
  environment       = "dev"

  # (Required) To enable Azure Monitoring and flow logs
  # Log Retention in days - Possible values range between 30 and 730
  # Log retention value to be inherited from the VNet-hub Module.
  storage_account_id                   = var.storage_account_id
  log_analytics_workspace_id           = var.log_analytics_workspace_id
  azure_monitor_logs_retention_in_days = var.azure_monitor_logs_retention_in_days

  # (Optional) To enable the availability zones for firewall.
  # Availability Zones can only be configured during deployment
  # You can't configure an existing firewall to include Availability Zones
  firewall_zones = [1, 2, 3]

  # (Required) specify the application rules for Azure Firewall
  firewall_application_rules = [
    {
      name             = "microsoft"
      action           = "Allow"
      source_addresses = ["10.0.0.0/8"]
      target_fqdns     = ["*.microsoft.com"]
      protocol = {
        type = "Http"
        port = "80"
      }
    },
  ]

  # (Required) specify the Network rules for Azure Firewall
  firewall_network_rules = [
    {
      name                  = "ntp"
      action                = "Allow"
      source_addresses      = ["10.0.0.0/8"]
      destination_ports     = ["123"]
      destination_addresses = ["*"]
      protocols             = ["UDP"]
    },
  ]

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a varible.
  tags = {
    ProjectName  = "tieto-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

## Terraform Usage

To run this example you need to execute following Terraform commands

``` hcl
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.

## Outputs

Name | Description
---- | -----------
`public_ip_prefix_id`|The id of the Public IP Prefix resource
`firewall_public_ip`|The public IP of firewall
`firewall_public_ip_fqdn`|Fully qualified domain name of the A DNS record associated with the public IP
`firewall_private_ip`|The private IP of firewall
`firewall_id`|The Resource ID of the Azure Firewall
`firewall_name`|The name of the Azure Firewall
