#!/bin/bash
set -e

# YOUR Project Details
DEV_REPO="deepakk007/project3-dev"
PROD_REPO="deepakk007/project3-prod"
SSH_KEY="./jenkins-key.pem"  # Pipeline copies this
SERVER_USER="ec2-user"
SERVER_IP="3.235.191.91"     # YOUR EC2

# Get branch
if [ -n "$GIT_BRANCH" ]; then
    CURRENT_BRANCH="$GIT_BRANCH"
else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Deploying branch: $CURRENT_BRANCH"

# Select repo
if [ "$CURRENT_BRANCH" == "dev" ] || [ "$CURRENT_BRANCH" == "origin/dev" ]; then
    REPO=$DEV_REPO
elif [ "$CURRENT_BRANCH" == "master" ] || [ "$CURRENT_BRANCH" == "origin/master" ] || [ "$CURRENT_BRANCH" == "main" ] || [ "$CURRENT_BRANCH" == "origin/main" ]; then
    REPO=$PROD_REPO
else
    echo "❌ Branch '$CURRENT_BRANCH' not supported"
    exit 1
fi

echo "Deploying $REPO to $SERVER_IP"

# Deploy script
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "
    echo '$DOCKER_PASSWORD' | docker login -u $DOCKER_USERNAME --password-stdin &&
    docker pull $REPO:latest &&
    docker stop react-app || true &&
    docker rm -f react-app &&
    docker run -d --name react-app -p 80:80 --restart unless-stopped $REPO:latest &&
    sleep 3 &&
    curl -s localhost | head -5 &&
    echo '✅ LIVE at http://$SERVER_IP'
"

echo "🎉 Deployment complete!"
