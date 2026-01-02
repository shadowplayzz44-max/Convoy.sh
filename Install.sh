#!/bin/bash

clear
echo "====================================="
echo "        Powered By Shadow"
echo "====================================="
sleep 1

if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root!"
   exit 1
fi

echo "🚀 Installing Convoy Panel..."
sleep 2

apt update -y
apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git

LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

apt install -y \
nginx \
mariadb-server \
mariadb-client \
redis-server \
tar unzip git \
php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring \
php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip \
composer

mysql_secure_installation

cd /var/www/
mkdir -p convoy
cd convoy

echo "⬇️ Downloading Convoy Panel..."
curl -Lo convoy.tar.gz https://github.com/ConvoyPanel/panel/archive/refs/heads/main.tar.gz
tar -xzvf convoy.tar.gz --strip 1

chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env

composer install --no-dev --optimize-autoloader
php artisan key:generate --force

cat <<EOF > /etc/nginx/sites-available/convoy.conf
server {
    listen 80;
    server_name _;
    root /var/www/convoy/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

ln -s /etc/nginx/sites-available/convoy.conf /etc/nginx/sites-enabled/
systemctl restart nginx
systemctl enable nginx redis mariadb

echo
echo "-------------------------------------------"
echo "Convoy installed files successfully!"
echo "Now run these manually:"
echo " 1) php artisan convoy:environment:setup"
echo " 2) php artisan convoy:environment:database"
echo " 3) php artisan migrate --seed --force"
echo "-------------------------------------------"

echo
echo "====================================="
echo " Convoy Installation Completed"
echo " Powered By Shadow"
echo "====================================="
