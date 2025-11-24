source "azure-arm" "ubuntu" {
  
  use_azure_cli_auth = true
  
  subscription_id = "f590d292-dc23-4abb-8e41-435dd1de9082"


  managed_image_name                = "node-nginx-image"
  managed_image_resource_group_name = "packer-rg"
  location                          = "West Europe"


  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
  image_version   = "latest"

  ssh_username = "azureuser"
  vm_size      = "Standard_B1s"
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

  # Deprovision para Azure
  provisioner "shell" {
    inline = [
      "sudo waagent -force"
    ]
    expect_disconnect = true
  }

provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y curl gnupg nginx",
      "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -",
      "apt-get install -y nodejs",
      "npm install -g pm2",
      "mkdir -p /home/azureuser/app",
      "cp /tmp/app.js /home/azureuser/app/",
      "cp /tmp/package.json /home/azureuser/app/",
      "chown -R azureuser:azureuser /home/azureuser/app",
      "cd /home/azureuser/app",
      "npm install",
      "pm2 start app.js --name node-app",
      "pm2 save",
      "pm2 startup systemd -u azureuser --hp /home/azureuser",
      "cat > /etc/nginx/sites-available/default <<EOL\nserver {\n    listen 80;\n    server_name _;\n\n    location / {\n        proxy_pass http://localhost:3000;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade \$http_upgrade;\n        proxy_set_header Connection 'upgrade';\n        proxy_set_header Host \$host;\n        proxy_cache_bypass \$http_upgrade;\n    }\n}\nEOL",
      "nginx -t",
      "systemctl restart nginx"
    ]
  }

}
