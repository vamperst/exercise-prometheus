#!/bin/bash
  
# sleep until instance is ready
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo echo "[Service]" >> /etc/systemd/system/docker.service.d/options.conf
sudo echo "ExecStart=" >> /etc/systemd/system/docker.service.d/options.conf
sudo echo "ExecStart=/usr/bin/dockerd -H unix:// -H tcp://0.0.0.0:2375" >> /etc/systemd/system/docker.service.d/options.conf

sudo systemctl daemon-reload
sudo systemctl restart docker

docker swarm init

