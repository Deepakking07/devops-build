#!/bin/bash
apt-get update -y
apt-get install -y docker.io curl wget
systemctl enable --now docker

docker pull deepakk007/project3-prod:latest
docker run -d --name react-app -p 80:80 deepakk007/project3-prod:latest
