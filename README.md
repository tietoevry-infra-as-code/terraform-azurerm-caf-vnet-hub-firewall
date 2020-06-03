# Azure Firewall Terraform Module

Azure Firewall is a managed, cloud-based network security service that protects your Azure Virtual Network resources. It's a fully stateful firewall as a service with built-in high availability and unrestricted cloud scalability.

![firewall-threat](https://docs.microsoft.com/en-us/azure/firewall/media/overview/firewall-threat.png)

Source: [Azure Firewall Documentation](https://docs.microsoft.com/en-us/azure/firewall/overview)

You can centrally create, enforce, and log application and network connectivity policies across subscriptions and virtual networks. Azure Firewall uses a static public IP address for your virtual network resources allowing outside firewalls to identify traffic originating from your virtual network. The service is fully integrated with Azure Monitor for logging and analytics.

## PreRequisites

This module depend on following resources availability. To create these pre-requisites, use [`terraform-azurerm-caf-vnet-hub`](https://github.com/tietoevry-infra-as-code/terraform-azurerm-caf-vnet-hub).

* Resource Group
* Location
* VNet Name
* VNet Address Space
* Route Table Name
* Storage Account Id
* Log Analytics Workspace Id
* Log Retention days for Azure Monitoring Data

## Module Usage

``` cs
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

## Availability Zones

Azure Firewall can be configured during deployment to span multiple Availability Zones for increased availability. With Availability Zones, your availability increases to 99.99% uptime.  

To specifies the availability zones in which the Azure Firewall should be created, set the argument `firewall_zones = [1, 2, 3]`.  This is by default is not enabled and set to `none`. There's no additional cost for a firewall deployed in an Availability Zone. However, there are additional costs for inbound and outbound data transfers associated with Availability Zones.

> **Note: Availability Zones can only be configured during deployment. You can't configure an existing firewall to include Availability Zones**

## Firewall Rules

This module centrally create allow or deny network filtering rules by source and destination IP address, port, and protocol. Azure Firewall is fully stateful, so it can distinguish legitimate packets for different types of connections. Rules are enforced and logged across multiple subscriptions and virtual networks.

To define the firewall rules, use the input variables `firewall_application_rules`, `firewall_network_rules` and `firewall_nat_rules`.

``` hcl
module "hub-firewall" {
  source = "github.com/tietoevry-infra-as-code/terraform-azurerm-caf-vnet-hub-firewall?ref=v1.0.0"

# ....omitted

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

# ....omitted
}
```

## Azure Monitoring Diagnostics

Platform logs in Azure, including the Azure Activity log and resource logs, provide detailed diagnostic and auditing information for Azure resources and the Azure platform they depend on. Platform metrics are collected by default and typically stored in the Azure Monitor metrics database. This module enables to send all the logs and metrics to either storage account, event hub or Log Analytics workspace.

## Recommended naming and tagging conventions

Well-defined naming and metadata tagging conventions help to quickly locate and manage resources. These conventions also help associate cloud usage costs with business teams via chargeback and show back accounting mechanisms.

> ### Resource naming

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production SharePoint workload is named like this: `pip-sharepoint-prod-westus-001`.

> ### Metadata tags

When applying metadata tags to the cloud resources, you can include information about those assets that couldn't be included in the resource name. You can use that information to perform more sophisticated filtering and reporting on resources. This information can be used by IT or business teams to find resources or generate reports about resource usage and billing.

The following list provides the recommended common tags that capture important context and information about resources. Use this list as a starting point to establish your tagging conventions.

Tag Name|Description|Key|ExampleValue|Required?
--------|-----------|---|------------|---------|
Project Name|Name of the Project for the infra is created. This is mandatory to create a resource names.|ProjectName|{Project name}|Yes
Application Name|Name of the application, service, or workload the resource is associated with.|ApplicationName|{app name}|Yes
Approver|Name Person responsible for approving costs related to this resource.|Approver|{email}|Yes
Business Unit|Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate or shared top-level organizational element.|BusinessUnit|FINANCE, MARKETING,{Product Name},CORP,SHARED|Yes
Cost Center|Accounting cost center associated with this resource.|CostCenter|{number}|Yes
Disaster Recovery|Business criticality of this application, workload, or service.|DR|Mission Critical, Critical, Essential|Yes
Environment|Deployment environment of this application, workload, or service.|Env|Prod, Dev, QA, Stage, Test|Yes
Owner Name|Owner of the application, workload, or service.|Owner|{email}|Yes
Requester Name|User that requested the creation of this application.|Requestor| {email}|Yes
Service Class|Service Level Agreement level of this application, workload, or service.|ServiceClass|Dev, Bronze, Silver, Gold|Yes
Start Date of the project|Date when this application, workload, or service was first deployed.|StartDate|{date}|No
End Date of the Project|Date when this application, workload, or service is planned to be retired.|EndDate|{date}|No

> This module allows you to manage the above metadata tags directly or as a variable using `variables.tf`. All Azure resources which support tagging can be tagged by specifying key-values in argument `tags`. Tag `ResourceName` is added automatically on all resources.

``` hcl
module "hub-firewall" {
  source = "github.com/tietoevry-infra-as-code/terraform-azurerm-caf-vnet-hub-firewall?ref=v1.0.0"
  create_resource_group   = false

  # ... omitted

  tags = {
    ProjectName  = "tieto-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}  
```

## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`resource_group_name` | The name of the resource group in which resources are created | string | `""`
`location`|The location of the resource group in which resources are created| string | `""`
`virtual_network_name`|The name of the virtual network| string | `""`
`virtual_network_address_space`|The address space to be used for the Azure virtual network| string | `[]`
`route_table_name`|The route table name|string|`""`
`firewall_service_endpoints`|Service endpoints to add to the firewall subnet|list(string)| `["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage"]`
`public_ip_names`|Public IPs is a list of IP names that are connected to the firewall|list(string)|["fw-public"]
`firewall_zones`|A collection of availability zones to spread the Firewall over|list(string)| `null`
`firewall_application_rules`|List of network rules to apply to firewall|list|`[]`
`firewall_nat_rules`|List of NAT rules to apply to firewall|list|`[]`
`fw_pip_diag_logs`|Firewall Public IP Monitoring Category details for Azure Diagnostic setting|list(string)|`["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports"]`
`fw_diag_logs`|Firewall Monitoring Category details for Azure Diagnostic setting|list(string)|`["AzureFirewallApplicationRule", "AzureFirewallNetworkRule"]`
`storage_account_id`|The ID of the storage account|string|`""`
`log_analytics_workspace_id`|The resource id of the log analytics workspace|string|`""`
`azure_monitor_logs_retention_in_days`|The log analytics workspace data retention in days. Possible values range between `30` and `730`.|number|`30`
`Tags`|A map of tags to add to all resources|map|`{}`

## Outputs

Name | Description
---- | -----------
`public_ip_prefix_id`|The id of the Public IP Prefix resource
`firewall_public_ip`|The public IP of firewall
`firewall_public_ip_fqdn`|Fully qualified domain name of the A DNS record associated with the public IP
`firewall_name`|The name of the Azure Firewall
`firewall_id`|The Resource ID of the Azure Firewall
`firewall_private_ip`|The private IP of firewall

## Resource Graph

![Resource Graph](graph.png)

## Authors

Module is maintained by [Kumaraswamy Vithanala](mailto:kumaraswamy.vithanala@tieto.com) with the help from other awesome contributors.

## Other resources

* [Azure Firewall Documentation](https://docs.microsoft.com/en-us/azure/firewall/overview)

* [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
