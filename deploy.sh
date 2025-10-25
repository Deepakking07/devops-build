#!/bin/bash
set -e

# Usage: ./deploy.sh dev|main
BRANCH=${1:-dev}
EC2_USER=${EC2_USER:-ubuntu}
EC2_IP=${EC2_IP:-<EC2_PUBLIC_IP>}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
DOCKERHUB_USER=${DOCKERHUB_USER:-deepakk007}
DOCKERHUB_PASS=${DOCKERHUB_PASS:-""}
REMOTE_DIR="/home/${EC2_USER}/app"

# Choose Docker image repo name
if [ "$BRANCH" = "main" ]; then
    REPO_NAME="devops-build-prod"
else
    REPO_NAME="devops-build-dev"
fi

IMAGE_NAME="${DOCKERHUB_USER}/${REPO_NAME}:${BRANCH}-latest"

echo "🚀 Deploying ${IMAGE_NAME} to ${EC2_USER}@${EC2_IP}"

# 1️⃣ Create remote directory if not exists
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "mkdir -p ${REMOTE_DIR}"

# 2️⃣ Send docker-compose.yml dynamically
cat <<EOF | ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" "cat > ${REMOTE_DIR}/docker-compose.yml"
version: "3.8"

services:
  web:
    image: ${IMAGE_NAME}
    ports:
      - "80:80"
    restart: unless-stopped
EOF

# 3️⃣ Deploy container remotely
ssh -i "${SSH_KEY}" "${EC2_USER}@${EC2_IP}" bash -s <<EOF
set -e
cd ${REMOTE_DIR}

echo "🧹 Cleaning up old containers..."
docker compose down || true

# Docker login (non-interactive if creds are set)
if [ -n "$DOCKERHUB_PASS" ]; then
  echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
else
  docker login
fi

echo "📥 Pulling latest image..."
docker compose pull

echo "🚀 Starting new container..."
docker compose up -d

EOF

echo "✅ Deployment complete! Visit: http://${EC2_IP}"

