# Owncloud-3-capas

## Índice

1. [Fichero Vagrantfile](#fichero-vagrantfile)  
2. [Fichero de aprovisionamiento del balanceador](#fichero-de-aprovisionamiento-del-balanceador)  
3. [Fichero de aprovisionamiento del NFS](#fichero-de-aprovisionamiento-del-nfs)  
4. [Fichero de aprovisionamiento del servidor web](#fichero-de-aprovisionamiento-del-servidor-web)  
5. [Fichero de aprovisionamiento de la base de datos](#fichero-de-aprovisionamiento-de-la-base-de-datos)  
6. [Contraseñas y problemas](#contraseñas-y-problemas)

## Fichero Vagrantfile
Este será nuestro fichero de Vagrantfile en el que tendremos tres capas. La primera que será la del balanceador donde tendremos una ip pública para conectarnos a nuestra página y una ip privada para conectarnos a la capa dos. La segunda capa tendremos dos servidores uno que será el nfs y dos que serán los servidores web que irán conectados a dos ips privadas, una para conectarse con el balanceador y otra para conectarse con la base de datos. Y la tercera capa donde tendremos una sola ip privada que servirá para que se conecten los servidores web.

```
Vagrant.configure("2") do |config|

  # Servidor de base de datos
  config.vm.define "dbGodino" do |db|
    db.vm.box = "debian/bullseye64"
    db.vm.network "private_network", ip: "192.168.57.14", virtualbox__intnet: "prnetwork_db"
    db.vm.provision "shell", path: "db.sh"
  end

  # Servidor NFS
  config.vm.define "NFSGodino" do |nfs|
    nfs.vm.box = "debian/bullseye64"
    nfs.vm.network "private_network", ip: "192.168.56.13", virtualbox__intnet: "prnetwork"
    nfs.vm.network "private_network", ip: "192.168.57.13", virtualbox__intnet: "prnetwork_db"
    nfs.vm.provision "shell", path: "nfs.sh"
  end

  # Servidores web
  config.vm.define "web1Godino" do |serverweb1|
    serverweb1.vm.box = "debian/bullseye64"
    serverweb1.vm.network "private_network", ip: "192.168.56.11", virtualbox__intnet: "prnetwork"
    serverweb1.vm.network "private_network", ip: "192.168.57.11", virtualbox__intnet: "prnetwork_db"
    serverweb1.vm.provision "shell", path: "web.sh"
  end

  config.vm.define "web2Godino" do |serverweb2|
    serverweb2.vm.box = "debian/bullseye64"
    serverweb2.vm.network "private_network", ip: "192.168.56.12", virtualbox__intnet: "prnetwork"
    serverweb2.vm.network "private_network", ip: "192.168.57.12", virtualbox__intnet: "prnetwork_db"
    serverweb2.vm.provision "shell", path: "web.sh"
  end

  # Máquina balanceador
  config.vm.define "balanceadorGodino" do |balanceador|
    balanceador.vm.box = "debian/bullseye64"
    balanceador.vm.network "public_network"
    balanceador.vm.network "forwarded_port", guest: 80, host: 8080
    balanceador.vm.network "private_network", ip: "192.168.56.10", virtualbox__intnet: "prnetwork"
    balanceador.vm.provision "shell", path: "balanceador.sh"
  end

end
```

## Fichero de aprovisionamiento del balanceador

En el fichero de aprovisionamiento de nuestro balanceador instalamos nginx que será el programa que nos permitirá mostrar nuestra página web que estará almacenada en nuestros dos servidores webs. El balanceador elegirá un servidor u otro en función de si uno está apagado o no.

```
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
```
## Fichero de aprovisionamiento del NFS

En este fichero lo que haremos será crear un almacenamiento compartido entre los dos servidores web, también instalaremos aquí el owncloud donde configuraremos el fichero config.php con los datos de la base de datos y con la personalización que nos pide en la práctica. Mi personalización trata de cambiar el color de fondo de blanco a verde clarito.

```
#!/bin/bash

# Actualizar repositorios e instalar NFS y PHP 7.4
apt-get update -y
apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip curl

# Crear carpeta compartida para OwnCloud y configurar permisos
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configurar NFS para compartir la carpeta
echo "/var/www/html 192.168.56.11(rw,sync,no_subtree_check)" >> /etc/exports
echo "/var/www/html 192.168.56.12(rw,sync,no_subtree_check)" >> /etc/exports

# Reiniciar NFS para aplicar cambios
exportfs -a
systemctl restart nfs-kernel-server

# Descargar y configurar OwnCloud
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
unzip owncloud-10.9.1.zip
mv owncloud /var/www/html/

# Configurar permisos de OwnCloud
chown -R www-data:www-data /var/www/html/owncloud
chmod -R 755 /var/www/html/owncloud

# Crear archivo de configuración inicial para OwnCloud
cat <<EOF > /var/www/html/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype" => "mysql",
  "dbname" => "owncloud",
  "dbuser" => "owncloud",
  "dbpassword" => "1234",
  "dbhost" => "192.168.57.14",
  "directory" => "/var/www/html/owncloud/data",
  "adminlogin" => "admin",
  "adminpass" => "1234"
);
EOF

# Cambiar color de fondo owncloud
sed -i 's/background-color: .*/background-color: #a8d08d;/'  /var/www/html/owncloud/core/css/styles.css


# Configuración de PHP-FPM para escuchar en la IP del servidor NFS
sed -i 's/^listen = .*/listen = 192.168.56.13:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Reiniciar PHP-FPM
systemctl restart php7.4-fpm

# Quitar ip por defecto para no tener acceso a internet
ip route del default
```

## Fichero de aprovisionamiento del servidor web

En los servidores web instalaremos php para nuestra página web, mariadb para conectarnos a la base de datos, nfs para conectarnos al servidor nfs y por último nginx para conectarnos a el balanceador. 

```
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
```

## Fichero de aprovisionamiento de la base de datos

Por ultimos en la base de datos instalaremos el servidor de mariadb donde crearemos nuestra base de datos y usuario para nuestro owncloud
```
#!/bin/bash

# Actualizar repositorios e instalar MariaDB
apt-get update -y
apt-get install -y mariadb-server

# Configurar MariaDB para permitir acceso remoto desde los servidores web
sed -i 's/bind-address.*/bind-address = 192.168.57.14/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Reiniciar MariaDB
systemctl restart mariadb

# Crear base de datos y usuario para OwnCloud
mysql -u root <<EOF
CREATE DATABASE owncloud;
CREATE USER 'owncloud'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'%';
FLUSH PRIVILEGES;
EOF

# Quitar ip por defecto para no tener acceso a internet
ip route del default
```

## Contraseñas y problemas

Usuario: admin
Contraseña: 1234

Problemas: No he conseguido que se pueda acceder con localhost:8080, he probado muchas cosas pero nada. Tienes que hacer un ssh en el balanceador, ahí un ip a para ver su ip pública y esa ip ponerla en el buscador.
