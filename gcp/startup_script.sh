#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y nginx nodejs npm git
mkdir -p /var/www/my-node-app

git clone https://github.com/Arrizki16/lb-provisioning.git /var/www/my-node-app

cd /var/www/my-node-app
npm install

cat <<EOF > /etc/nginx/sites-available/my-node-app
server {
    listen 80;
    server_name localhost:80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/my-node-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

nohup npm start &
echo "Startup script execution completed."
