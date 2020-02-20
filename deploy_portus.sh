#!/bin/bash
# Author - Akshay Gupta
apt install sudo
sudo apt update
if [ -z $(which docker) ]
then
    apt -y install docker.io
fi
if [ -z $(which docker-compose) ]
then
    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
if [ -z $(which certbot) ]
then
    apt install certbot python-certbot-nginx -y
fi
if [ $(docker network ls | grep 'service-layer' -c) != 1 ]
then
    docker network create service-layer
fi
cd /root
if [ ! -d Portus ]
then
    git clone https://github.com/gogenius1/Portus.git
fi
cd Portus/examples/compose/
if [ ! -d /etc/letsencrypt/live/portus.ixxo.io ]
then
    certbot --nginx -d portus.ixxo.io --register-unsafely-without-email -n --agree-tos
    killall nginx
    cp /etc/letsencrypt/archive/portus.ixxo.io/* secrets/ -r
    sed -i 's/portus.crt/fullchain1.pem/g' nginx/nginx.conf
    sed -i 's/portus.key/privkey1.pem/g' nginx/nginx.conf
fi
if [ ! -f secrets/portus.crt ] || [ ! -f secrets/portus.key ]
then
    cd secrets
    openssl genrsa -des3 -out server.key 4096
    openssl req -new -key server.key -out server.csr
    cp server.key server.key.org
    openssl rsa -in server.key.org -out server.key
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    mv server.crt portus.crt
    mv server.key portus.key
    cd ..
fi
sed -i 's/MACHINE_FQDN=.*$/MACHINE_FQDN=portus.ixxo.io/g' .env
if [ $(cat /lib/systemd/system/docker.service | grep insecure -c) != 1 ]
then
    sed -i 's/containerd.sock.*$/containerd.sock --insecure-registry portus.ixxo.io:5000/g' /lib/systemd/system/docker.service
    systemctl daemon-reload
    service docker restart
fi
docker-compose down
docker-compose up -d
echo "Docker Registry - portus.ixxo.io"
echo "Note: Tag your images with portus.ixxo.io and not with portus.ixxo.io:5000"
