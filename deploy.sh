#!/bin/bash
echo "🚀 Detected branch: $GIT_BRANCH"
echo "🔑 Using SSH key: ./jenkins-key.pem"
echo "🎯 React server: 3.235.191.91"
echo "🔄 Deploying from repository: $DOCKER_REPO"

ssh -i ./jenkins-key.pem -o StrictHostKeyChecking=no ec2-user@3.235.191.91 "
    echo '🔄 Stopping existing container...'
    docker stop react-app || true
    docker rm react-app || true
    
    echo '📥 Pulling latest image...'
    docker pull $DOCKER_REPO:latest
    
    echo '🏃 Starting new container...'
    docker run -d --name react-app -p 80:80 $DOCKER_REPO:latest
    
    echo '✅ Deployment complete!'
    docker ps | grep react-app
"
