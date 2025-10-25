#!/bin/bash
set -e

# Usage: ./build.sh dev|main
BRANCH=${1:-dev}

# DockerHub credentials (can be passed by Jenkins credentials or exported manually)
DOCKERHUB_USER=${DOCKERHUB_USER:-deepakk007}
DOCKERHUB_PASS=${DOCKERHUB_PASS:-""}

# Decide which DockerHub repo to use based on branch
if [ "$BRANCH" = "main" ]; then
    REPO_NAME="devops-build-prod"
else
    REPO_NAME="devops-build-dev"
fi

IMAGE_NAME="${DOCKERHUB_USER}/${REPO_NAME}:${BRANCH}-$(date +%Y%m%d%H%M)"
LATEST_TAG="${DOCKERHUB_USER}/${REPO_NAME}:${BRANCH}-latest"

echo "🚀 Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" .

# Tag the latest version
docker tag "${IMAGE_NAME}" "${LATEST_TAG}"

# Docker login (non-interactive for CI/CD)
if [ -n "$DOCKERHUB_PASS" ]; then
    echo "🔐 Logging into Docker Hub using environment variables..."
    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
else
    echo "🔐 Logging into Docker Hub interactively..."
    docker login
fi

# Push both tags
echo "📤 Pushing Docker images to ${REPO_NAME}..."
docker push "${IMAGE_NAME}"
docker push "${LATEST_TAG}"

echo "✅ Docker images pushed successfully!"

