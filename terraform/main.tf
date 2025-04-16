provider "azurerm" {
  features {}
  subscription_id = "85b87ac7-2879-4c21-a8ad-a45ac94c5fff"
}

resource "azurerm_resource_group" "rg" {
  name     = "mysherin-newrg"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "mysherinacrregistry123"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mysherinakscluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2ms"
    # Linux OS is used by default – no need to set os_type
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Dev"
  }
}
