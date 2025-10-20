#!/bin/bash
set -e

# Usage: ./deploy.sh dev|main
BRANCH=${1:-dev}
EC2_USER=${EC2_USER:-ubuntu}
EC2_IP=${EC2_IP:-<EC2_PUBLIC_IP>}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
DOCKERHUB_USER=${DOCKERHUB_USER:-your_dockerhub_username}
REMOTE_DIR="/home/${EC2_USER}/app"

IMAGE_NAME="${DOCKERHUB_USER}/devops-build:${BRANCH}-latest"

echo "Deploying ${IMAGE_NAME} to ${EC2_USER}@${EC2_IP}"

# Create remote directory
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "mkdir -p ${REMOTE_DIR}"

# Copy docker-compose.yml to remote
cat <<EOF | ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "cat > ${REMOTE_DIR}/docker-compose.yml"
version: "3.8"
services:
  web:
    image: ${IMAGE_NAME}
    ports:
      - "80:80"
    restart: unless-stopped
EOF

# Pull & run container remotely
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" <<EOF
cd ${REMOTE_DIR}
docker login
docker-compose pull || true
docker-compose up -d --remove-orphans
EOF

echo "Deployment completed. Visit http://${EC2_IP}"

