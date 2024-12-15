#!/bin/bash

# Actualizar repositorios e instalar nginx
apt-get update -y
apt-get install -y nginx

# Configuración de Nginx como balanceador de carga
cat <<EOF > /etc/nginx/sites-available/default
upstream backend_servers {
    server 192.168.56.11;
    server 192.168.56.12;
}

server {
    listen 80;
    server_name localhost;
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Reiniciar nginx para aplicar cambios
systemctl restart nginx