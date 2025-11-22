source "azure-arm" "ubuntu" {
  # Autenticación usando Azure CLI (NO service principal)
  use_azure_cli_auth = true

  # Tu Subscription ID az account show --query id -o tsv
  subscription_id = "f590d292-dc23-4abb-8e41-435dd1de9082"

  # Configuración de la imagen administrada
  managed_image_name                = "node-nginx-image"
  managed_image_resource_group_name = "packer-rg"
  location                          = "West Europe"

  # Sistema base (Ubuntu 20.04)
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-focal"
  image_sku       = "20_04-lts"
  image_version   = "latest"

  ssh_username = "azureuser"

  vm_size = "Standard_B1s"
}


build {
  name    = "ubuntu-node-nginx"
  sources = ["source.azure-arm.ubuntu"]

  provisioner "shell" {
    script = "scripts/install_node.sh"
  }

  provisioner "shell" {
    script = "scripts/install_nginx.sh"
  }

  provisioner "shell" {
    script = "scripts/configure_nginx.sh"
  }
}
