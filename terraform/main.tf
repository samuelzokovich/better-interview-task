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
