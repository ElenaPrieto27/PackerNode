packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
  }
}

# =========================
# VARIABLES
# =========================
variable "azure_ssh_username" {
  type    = string
  default = "azureuser"
}

variable "aws_ssh_username" {
  type    = string
  default = "ubuntu"
}

# =========================
# AZURE BUILDER
# =========================
source "azure-arm" "ubuntu" {
  use_azure_cli_auth = true
  subscription_id    = "f590d292-dc23-4abb-8e41-435dd1de9082"

  managed_image_name                = "node-nginx-image-v2"
  managed_image_resource_group_name = "packer-rg"
  location                          = "West Europe"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
  image_version   = "latest"

  ssh_username = var.azure_ssh_username
  vm_size      = "Standard_B1s"
}

# =========================
# AWS BUILDER
# =========================
source "amazon-ebs" "aws-node-nginx" {
  region        = "us-east-1"
  instance_type = "t2.micro"
  ssh_username  = var.aws_ssh_username

  ami_name = "node-nginx-image-aws-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

# =========================
# BUILD MULTINUBE
# =========================
build {
  name = "ubuntu-node-nginx"

  sources = [
    "source.azure-arm.ubuntu",
    "source.amazon-ebs.aws-node-nginx"
  ]

  # =========================
  # CREAR ARCHIVOS APP.JS Y PACKAGE.JSON
  # =========================
  provisioner "shell" {
    inline = [
      <<-EOF
      sudo mkdir -p /tmp/app
      cat << 'EOL' | sudo tee /tmp/app/app.js > /dev/null
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hola Mundo desde la imagen Packer multinube!');
});

server.listen(3000, () => {
  console.log('Servidor Node corriendo en puerto 3000');
});
EOL
EOF
      ,
      <<-EOF
      cat << 'EOL' | sudo tee /tmp/app/package.json > /dev/null
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {}
}
EOL
EOF
    ]
  }

  # =========================
  # INSTALACIÓN Y CONFIGURACIÓN
  # =========================
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y curl gnupg nginx",
      "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo npm install -g pm2",

      # Crear carpeta app y copiar archivos según builder
      "mkdir -p /home/${var.azure_ssh_username}/app || true",
      "mkdir -p /home/${var.aws_ssh_username}/app || true",
      "cp -r /tmp/app/* /home/${var.azure_ssh_username}/app/ || true",
      "cp -r /tmp/app/* /home/${var.aws_ssh_username}/app/ || true",
      "sudo chown -R ${var.azure_ssh_username}:${var.azure_ssh_username} /home/${var.azure_ssh_username}/app || true",
      "sudo chown -R ${var.aws_ssh_username}:${var.aws_ssh_username} /home/${var.aws_ssh_username}/app || true",

      # Instalar dependencias Node
      "cd /home/${var.azure_ssh_username}/app && npm install || true",
      "cd /home/${var.aws_ssh_username}/app && npm install || true",

      # Iniciar app con PM2
      "sudo -H -u ${var.azure_ssh_username} pm2 start /home/${var.azure_ssh_username}/app/app.js --name node-app || true",
      "sudo -H -u ${var.aws_ssh_username} pm2 start /home/${var.aws_ssh_username}/app/app.js --name node-app || true",
      "sudo -H -u ${var.azure_ssh_username} pm2 save || true",
      "sudo -H -u ${var.aws_ssh_username} pm2 save || true",
      "sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ${var.azure_ssh_username} --hp /home/${var.azure_ssh_username} || true",
      "sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ${var.aws_ssh_username} --hp /home/${var.aws_ssh_username} || true",

      # Configuración Nginx
      <<-EOF
      sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOL'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
EOF
      ,
      "sudo nginx -t",
      "sudo systemctl restart nginx"
    ]
  }

  # =========================
  # DEPROVISION SOLO PARA AZURE
  # =========================
  provisioner "shell" {
    only = ["azure-arm.ubuntu"]
    inline = [
      "sudo waagent -force"
    ]
    expect_disconnect = true
  }
}
