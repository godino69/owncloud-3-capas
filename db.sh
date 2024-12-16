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
