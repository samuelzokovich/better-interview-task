# 1. Create a resource group to hold all the resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Create the AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  # Define the primary node pool
  default_node_pool {
    name       = "default"
    node_count = 1
    # UPPING THE VM SIZE for the LLM
    vm_size    = "Standard_D4s_v3" 
  }

  # Use a system-assigned managed identity for simplicity and security
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

# 3. Create a Virtual Network and Subnet for AKS and Application Gateway
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
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
    subnet_id = azurerm_subnet.subnet.id
  }
  frontend_port {
    name = "frontend-port"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }
  backend_address_pool {
    name  = "backend-pool"
    # Hardcoded as of now!
    ip_addresses = "74.179.227.66"
  }
  backend_http_settings {
    name                  = "http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
  }
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
  }
  waf_configuration {
    enabled            = true
    firewall_mode      = "Prevention"
    rule_set_type      = "OWASP"
    rule_set_version   = "3.2"
  }
}

# 6. Azure Budget with Email Alert
resource "azurerm_consumption_budget_subscription" "budget" {
  name                = "llm-budget"
  subscription_id     = data.azurerm_client_config.current.subscription_id
  amount              = 3
  time_grain          = "Monthly"
  time_period {
    start_date = formatdate("YYYY-MM-DD", timestamp())
    end_date   = "2099-12-31"
  }
  notification {
    enabled        = true
    threshold      = 100
    contact_emails = [var.budget_email]
    contact_roles  = []
    notification_type = "Actual"
  }
}

# 7. Data source for subscription ID
data "azurerm_client_config" "current" {}