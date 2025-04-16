provider "azurerm" {
  features {}
  subscription_id = "85b87ac7-2879-4c21-a8ad-a45ac94c5fff"
}

resource "azurerm_resource_group" "main" {
  name     = "mysherin-newrg"
  location = "eastus2"
}

resource "azurerm_container_registry" "acr" {
  name                = "mysherinsajiacrregistry123"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mysherinsajiakscluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    =  "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = false

  network_profile {
    network_plugin = "azure"
  }

  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id  # Indexing the list correctly
  depends_on           = [azurerm_kubernetes_cluster.aks]
}
