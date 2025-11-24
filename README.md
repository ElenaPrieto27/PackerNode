# Despliegue de Node.js + Nginx con Packer en Azure

Proyecto de la materia **Herramientas DevOps** – Maestría en Desarrollo y Operaciones de Software (UNIR).

Se creó una imagen personalizada con **Packer** que incluye:
- Node.js
- Nginx (como proxy inverso)
- Ubuntu

Y se desplegó automáticamente en **Microsoft Azure** usando Azure CLI.

---

## Tecnologías

- Packer  
- Azure CLI  
- Azure  
- Ubuntu  
- Node.js  
- Nginx  

---

## Creación de imagen

```bash
packer validate template.json
packer build template.json

Verificación:
az image list --resource-group packer-rg -o table


Despliegue con Azure:
az vm create \
  --resource-group packer-rg \
  --name vm-node-nginx \
  --image node-nginx-image \
  --admin-username azureuser \
  --admin-password <CONTRASEÑA_SEGURA> \
  --location westeurope \
  --size Standard_B1s \
  --public-ip-sku Standard

Abrir puerto 80:
az vm open-port --resource-group packer-rg --name vm-node-nginx --port 80


Acceso desde el navegador:
http://<IP_PUBLICA>

Ejemplo:
http://172.201.54.120

Autora:
Maria Elena Prieto Goitia
UNIR – 2025
