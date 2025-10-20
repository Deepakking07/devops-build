#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build.sh dev|prod
TARGET=${1:-dev}
DOCKERHUB_USER=${DOCKERHUB_USER:-your_dockerhub_username}
IMAGE_NAME="${DOCKERHUB_USER}/devops-build:${TARGET}-$(date +%Y%m%d%H%M)"

echo "Building image ${IMAGE_NAME} ..."
docker build -t "${IMAGE_NAME}" .

echo "Tagging latest-${TARGET} ..."
docker tag "${IMAGE_NAME}" "${DOCKERHUB_USER}/devops-build:${TARGET}-latest"

echo "Logging into Docker Hub (ensure DOCKERHUB_PASS env var set) ..."
# recommended: docker login -u $DOCKERHUB_USER (then enter pass) or use docker login with token
docker push "${IMAGE_NAME}"
docker push "${DOCKERHUB_USER}/devops-build:${TARGET}-latest"

echo "Done: pushed ${IMAGE_NAME}"
