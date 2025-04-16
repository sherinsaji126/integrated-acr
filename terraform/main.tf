terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.94.0"
    }
  }
  required_version = ">=1.0.0"
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "85b87ac7-2879-4c21-a8ad-a45ac94c5fff"
  tenant_id                       = "4dd7a366-bffd-434d-ad00-bbbee4d2001f"
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

  tags = {
    environment = "dev"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mysherinsajiakscluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "dev"
  }

  depends_on = [azurerm_container_registry.acr]
}

# This ensures AKS identity is available after creation
data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]

  lifecycle {
    ignore_changes = [principal_id]
  }
}
