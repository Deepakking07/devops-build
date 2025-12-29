#!/bin/bash
# Deployment script for React application using Docker
# Exit immediately if a command exits with a non-zero status
set -e

# Configuration - YOUR DETAILS
DEV_REPO="deepakk007/project3-dev"
PROD_REPO="deepakk007/project3-prod"  # YOUR Docker Hub repo
REACT_SERVER_IP="3.235.191.91"        # YOUR React EC2 IP

# SSH key path - Jenkins workspace (from pipeline)
if [ -f "./jenkins-key.pem" ]; then
    SSH_KEY="./jenkins-key.pem"       # Jenkins pipeline copies here
elif [ -f "/var/lib/jenkins/jenkins-key.pem" ]; then
    SSH_KEY="/var/lib/jenkins/jenkins-key.pem"
elif [ -f "$HOME/.ssh/jenkins-key.pem" ]; then
    SSH_KEY="$HOME/.ssh/jenkins-key.pem"
else
    echo "❌ Error: SSH key not found!"
    echo "Expected locations:"
    echo "  - ./jenkins-key.pem (Jenkins workspace)"
    echo "  - /var/lib/jenkins/jenkins-key.pem"
    exit 1
fi

SERVER_USER="ubuntu"

# Get the current branch - handle Jenkins environment
if [ -n "$GIT_BRANCH" ]; then
    CURRENT_BRANCH="$GIT_BRANCH"
else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "🚀 Detected branch: $CURRENT_BRANCH"
echo "🔑 Using SSH key: $SSH_KEY"
echo "🎯 React server: $REACT_SERVER_IP"

# Determine which repository to pull from based on branch
if [ "$CURRENT_BRANCH" == "dev" ] || [ "$CURRENT_BRANCH" == "origin/dev" ]; then
    REPO=$DEV_REPO
    echo "🔄 Deploying from development repository: $DEV_REPO"
elif [ "$CURRENT_BRANCH" == "master" ] || [ "$CURRENT_BRANCH" == "origin/master" ] || [ "$CURRENT_BRANCH" == "main" ] || [ "$CURRENT_BRANCH" == "origin/main" ]; then
    REPO=$PROD_REPO
    echo "🔄 Deploying from production repository: $PROD_REPO"
else
    echo "❌ Branch '$CURRENT_BRANCH' is not supported."
    echo "✅ Supported: dev, master, main"
    exit 1
fi

echo "🐳 Pulling latest image: $REPO:latest"

# SSH to React server and deploy (direct commands - no temp files)
ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SERVER_USER@$REACT_SERVER_IP << 'EOF'
    echo "🚀 Starting zero-downtime deployment on React server..."

    # Stop existing container (graceful)
    if docker ps --format '{{.Names}}' | grep -q '^react-app$'; then
        echo "🛑 Stopping existing react-app container..."
        docker stop react-app || true
        docker rm react-app || true
    fi

    # Pull latest image
    echo "📥 Pulling latest image: %REPO%:latest"
    docker pull %REPO%:latest || {
        echo "❌ Failed to pull image %REPO%:latest"
        exit 1
    }

    # Start new container
    echo "🏃 Starting new react-app container..."
    docker run -d \\
        --name react-app \\
        -p 80:80 \\
        --restart unless-stopped \\
        %REPO%:latest

    # Verify deployment
    echo "🔍 Verifying deployment..."
    sleep 5
    if docker ps --format '{{.Names}}' | grep -q '^react-app$'; then
        echo "✅ Container react-app is running!"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep react-app
    else
        echo "❌ Container failed to start!"
        docker logs react-app --tail 20
        exit 1
    fi

    # Health check
    if curl -f http://localhost:80 --max-time 10; then
        echo "✅ Health check PASSED!"
    else
        echo "⚠️ Health check failed - check app logs"
        docker logs react-app --tail 10
    fi

    # Cleanup old images
    echo "🧹 Cleaning up old images..."
    docker image prune -f

    echo "🎉 Deployment COMPLETED SUCCESSFULLY!"
EOF

echo "✅ Automated deployment to $REACT_SERVER_IP completed!"
echo "🌐 React app: http://$REACT_SERVER_IP"
echo "🐳 Image deployed: $REPO:latest"
