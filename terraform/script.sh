#!/bin/bash
  
# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

curl -sSL https://get.docker.com/ | sudo sh
sudo usermod -aG docker ubuntu

