# 1. Create a resource group to hold all the resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Create the AKS cluster with AGIC addon
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = 1
    # Bumped up for LLM workloads
    vm_size    = "Standard_D4s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.waf.id
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  tags = {
    environment = "dev"
  }

  depends_on = [azurerm_application_gateway.waf]
}

# 3. Create a Virtual Network and Subnets for AKS and Application Gateway
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for Application Gateway
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "appgw-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Application Gateway with WAF
resource "azurerm_application_gateway" "waf" {
  name                = "appgw-waf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # AGIC will manage backend pools dynamically
  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "default-http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
  }

  http_listener {
    name                           = "default-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-http-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  ssl_policy {
    policy_type          = "Predefined"
    policy_name          = "AppGwSslPolicy20170401S"
    min_protocol_version = "TLSv1_2"
  }
}


# 6. Data source for subscription ID
data "azurerm_client_config" "current" {}

# 7. Azure Budget with Email Alert
resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "llm-budget"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  amount          = 3
  time_grain      = "Monthly"

  time_period {
    # Start date as RFC3339 format
    start_date = "2025-10-01T00:00:00Z"
    end_date   = "2025-12-31T00:00:00Z"
  }

  notification {
    enabled        = true
    operator       = "EqualTo"
    threshold      = 100
    threshold_type = "Actual"
    contact_emails = [var.budget_email]
    contact_roles  = []
  }
}
