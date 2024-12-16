#!/bin/bash

# Actualizar repositorios e instalar nginx, mariadb-client, nfs-common y PHP 7.4
apt-get update -y
apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client

# Crear directorio para montar la carpeta compartida por NFS
mkdir -p /var/www/html

# Montar la carpeta NFS desde el servidor NFS
mount -t nfs 192.168.56.13:/var/www/html /var/www/html

# Añadir entrada al /etc/fstab para montaje persistente
echo "192.168.56.13:/var/www/html /var/www/html nfs defaults 0 0" >> /etc/fstab

# Configuración de Nginx para servir OwnCloud
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;

    root /var/www/html/owncloud;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 192.168.56.13:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }
}
EOF

# Verificar la configuración de Nginx
nginx -t

# Reiniciar Nginx para aplicar los cambios
systemctl restart nginx

# Reiniciar PHP-FPM 7.4
systemctl restart php7.4-fpm

# Quitar ip por defecto para no tener acceso a internet
ip route del default
