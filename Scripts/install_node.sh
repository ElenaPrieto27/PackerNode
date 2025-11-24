#!/bin/bash
set -e

# No pedir interacción
export DEBIAN_FRONTEND=noninteractive

# Habilitar repos universe
sudo add-apt-repository universe -y
sudo apt-get update -y
sudo apt-get install -y build-essential curl

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PM2
sudo npm install -g pm2

# App básica Node
cat << 'EOF' > /home/azureuser/app.js
const http = require('http');
const port = 3000;

const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('¡Hola desde Node.js en Azure!');
});

server.listen(port, () => console.log(`Node.js app listening on port ${port}`));
EOF

sudo chown azureuser:azureuser /home/azureuser/app.js

# Iniciar PM2 como usuario
sudo -u azureuser pm2 start /home/azureuser/app.js --name node-app
sudo -u azureuser pm2 save
