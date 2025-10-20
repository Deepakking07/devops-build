#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy.sh <branch>   (branch: dev or prod)
BRANCH=${1:-dev}
EC2_USER=${EC2_USER:-ubuntu}
EC2_IP=${EC2_IP:-x.x.x.x}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
DOCKERHUB_USER=${DOCKERHUB_USER:-your_dockerhub_username}
REMOTE_DIR="/home/${EC2_USER}/app"

IMAGE_TAG="${DOCKERHUB_USER}/devops-build:${BRANCH}-latest"

echo "Deploying ${IMAGE_TAG} to ${EC2_USER}@${EC2_IP} ..."

# make remote dir
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "mkdir -p ${REMOTE_DIR}"

# create docker-compose.yml on remote
cat <<EOF | ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "cat > ${REMOTE_DIR}/docker-compose.yml"
version: "3.8"
services:
  web:
    image: ${IMAGE_TAG}
    ports:
      - "80:80"
    restart: unless-stopped
EOF

# Pull & up on remote
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" <<EOF
cd ${REMOTE_DIR}
docker login
docker-compose pull || true
docker-compose up -d --remove-orphans
EOF

echo "Deploy invoked. Visit http://${EC2_IP}/"
