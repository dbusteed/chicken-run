#!/usr/bin/bash

# IN PROGRESS!

apt-get update && apt-get upgrade -y
apt-get install nginx coturn -y
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
certbot --nginx  # needs input!

# TODO add the nginx ssl upgrade snippet
# Noninteractive?

wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz -O node.tar.xz
tar xf node.tar.xz
mv node-v20.11.0-linux-x64 node
export PATH=$PATH:/root/node/bin

git clone https://github.com/dbusteed/chicken-run
cd chicken-run/server
npm i


