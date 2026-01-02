#!/bin/bash

set -e

# YOUR Project Details
IMAGE_NAME="deepakk007/project3"
DEV_REPO="deepakk007/project3-dev"
PROD_REPO="deepakk007/project3-prod"

# Get current branch
if [ -n "$GIT_BRANCH" ]; then
    CURRENT_BRANCH="$GIT_BRANCH"
else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

TAG=$(date +%Y%m%d-%H%M%S)
echo "Building from branch: $CURRENT_BRANCH"

echo "Building Docker image..."
docker build -t $IMAGE_NAME:$TAG .

# Docker Hub login
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
fi

# Branch logic for YOUR repos
if [ "$CURRENT_BRANCH" == "dev" ] || [ "$CURRENT_BRANCH" == "origin/dev" ]; then
    echo "Tagging for dev..."
    docker tag $IMAGE_NAME:$TAG $DEV_REPO:$TAG
    docker tag $IMAGE_NAME:$TAG $DEV_REPO:latest
    docker push $DEV_REPO:$TAG
    docker push $DEV_REPO:latest
    echo "✅ Dev push: $DEV_REPO:latest"
    
elif [ "$CURRENT_BRANCH" == "master" ] || [ "$CURRENT_BRANCH" == "origin/master" ] || [ "$CURRENT_BRANCH" == "main" ] || [ "$CURRENT_BRANCH" == "origin/main" ]; then
    echo "Tagging for prod..."
    docker tag $IMAGE_NAME:$TAG $PROD_REPO:$TAG
    docker tag $IMAGE_NAME:$TAG $PROD_REPO:latest
    docker push $PROD_REPO:$TAG
    docker push $PROD_REPO:latest
    echo "✅ Prod push: $PROD_REPO:latest"
else
    echo "❌ Branch '$CURRENT_BRANCH' not supported"
    exit 1
fi

echo "🎉 Build complete!"
