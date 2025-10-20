#!/bin/bash
set -e

# Usage: ./build.sh dev|main
BRANCH=${1:-dev}
DOCKERHUB_USER=${DOCKERHUB_USER:-your_dockerhub_username}

IMAGE_NAME="${DOCKERHUB_USER}/devops-build:${BRANCH}-$(date +%Y%m%d%H%M)"

echo "Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" .

# Tag latest for branch
docker tag "${IMAGE_NAME}" "${DOCKERHUB_USER}/devops-build:${BRANCH}-latest"

echo "Login to Docker Hub (interactive or with token)"
docker login

echo "Pushing images to Docker Hub"
docker push "${IMAGE_NAME}"
docker push "${DOCKERHUB_USER}/devops-build:${BRANCH}-latest"

echo "Docker images pushed successfully!"

