#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx git
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

sudo npm install pm2 -g

sudo git clone https://github.com/Arrizki16/high-availability-web-infrastructure.git /var/www/app

cd /var/www/app/src
sudo echo "DB_NAME=\"rpl\"
DB_USER=\"rpl\"
DB_PASSWORD=\"password\"
DB_HOST=\"13.213.18.93\"
DB_PORT=3306" > .env
sudo npm install
sudo pm2 start ecosystem.config.cjs

sudo echo "server {  
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" > /etc/nginx/sites-available/app.conf

sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx