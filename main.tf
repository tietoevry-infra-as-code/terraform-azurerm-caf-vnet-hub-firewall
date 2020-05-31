locals {
  public_ip_map = { for pip in var.public_ip_names : pip => true }

  fw_nat_rules = { for idx, rule in var.firewall_nat_rules : rule.name => {
    idx : idx,
    rule : rule,
  } }

  fw_network_rules = { for idx, rule in var.firewall_network_rules : rule.name => {
    idx : idx,
    rule : rule,
  } }

  fw_application_rules = { for idx, rule in var.firewall_application_rules : rule.name => {
    idx : idx,
    rule : rule,
  } }
}

resource "azurerm_subnet" "fw-snet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name # Variable
  address_prefixes     = [cidrsubnet(element(var.virtual_network_address_space, 0), 8, 0)]
  service_endpoints    = var.firewall_service_endpoints
}

resource "random_string" "str" {
  for_each = local.public_ip_map
  length   = 6
  special  = false
  upper    = false
}

resource "azurerm_public_ip_prefix" "pip_prefix" {
  name                = lower("${var.project_name}-pip-prefix-${var.subscription_type}")
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = 30
  tags                = merge({ "ResourceName" = lower("${var.project_name}-pip-prefix-${var.subscription_type}") }, var.tags, )
}

resource "azurerm_public_ip" "fw-pip" {
  for_each            = local.public_ip_map
  name                = lower("pip-${var.project_name}-${each.key}-${var.location}")
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
  domain_name_label   = format("%s%s", lower(replace(each.key, "/[[:^alnum:]]/", "")), random_string.str[each.key].result)
  tags                = merge({ "ResourceName" = lower("pip-${var.project_name}-${each.key}-${var.location}") }, var.tags, )
}

resource "azurerm_firewall" "fw" {
  name                = lower("fw-${var.project_name}-${var.subscription_type}-${var.location}")
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.firewall_zones
  tags                = merge({ "ResourceName" = lower("fw-${var.project_name}-${var.subscription_type}-${var.location}") }, var.tags, )
  dynamic "ip_configuration" {
    for_each = local.public_ip_map
    iterator = ip
    content {
      name                 = ip.key
      subnet_id            = ip.key == var.public_ip_names[0] ? azurerm_subnet.fw-snet.id : null
      public_ip_address_id = azurerm_public_ip.fw-pip[ip.key].id
    }
  }
}

resource "azurerm_route" "rt" {
  name                   = lower("route-to-firewall-${var.project_name}-${var.location}")
  resource_group_name    = var.resource_group_name
  route_table_name       = var.route_table_name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration.0.private_ip_address
}

resource "azurerm_firewall_application_rule_collection" "fw_app" {
  for_each            = local.fw_application_rules
  name                = lower(format("fw-app-rule-%s-${var.environment}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name             = each.key
    source_addresses = each.value.rule.source_addresses
    target_fqdns     = each.value.rule.target_fqdns

    protocol {
      type = each.value.rule.protocol.type
      port = each.value.rule.protocol.port
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "fw" {
  for_each            = local.fw_network_rules
  name                = lower(format("fw-net-rule-%s-${var.environment}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = [for dest in each.value.rule.destination_addresses : contains(var.public_ip_names, dest) ? azurerm_public_ip.fw-pip[dest].ip_address : dest]
    protocols             = each.value.rule.protocols
  }
}

resource "azurerm_firewall_nat_rule_collection" "fw" {
  for_each            = local.fw_nat_rules
  name                = lower(format("fw-nat-rule-%s-${var.environment}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = [for dest in each.value.rule.destination_addresses : contains(var.public_ip_names, dest) ? azurerm_public_ip.fw-pip[dest].ip_address : dest]
    protocols             = each.value.rule.protocols
    translated_address    = each.value.rule.translated_address
    translated_port       = each.value.rule.translated_port
  }
}

resource "azurerm_monitor_diagnostic_setting" "fw-pip" {
  for_each                   = local.public_ip_map
  name                       = "${each.key}-pip-diag"
  target_resource_id         = azurerm_public_ip.fw-pip[each.key].id
  storage_account_id         = var.storage_account_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = var.fw_pip_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = var.azure_monitor_logs_retention_in_days
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.azure_monitor_logs_retention_in_days
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "fw-diag" {
  name                       = lower("fw-${var.project_name}-diag")
  target_resource_id         = azurerm_firewall.fw.id
  storage_account_id         = var.storage_account_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = var.fw_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = var.azure_monitor_logs_retention_in_days
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.azure_monitor_logs_retention_in_days
    }
  }
}
