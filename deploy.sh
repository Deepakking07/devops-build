#!/bin/bash
echo "🚀 Detected branch: origin/main"
echo "🔑 Using SSH key: /var/lib/jenkins/jenkins-key.pem"
echo "🎯 React server: 3.235.191.91"
echo "🔄 Deploying: $DOCKER_REPO"

ssh -i /var/lib/jenkins/jenkins-key.pem -o StrictHostKeyChecking=no ec2-user@3.235.191.91 "
    echo '🔄 Stopping container...'
    sudo docker stop react-app || true
    sudo docker rm react-app || true
    
    echo '📥 Pulling image...'
    sudo docker pull $DOCKER_REPO:latest
    
    echo '🏃 Starting container...'
    sudo docker run -d --name react-app -p 80:80 $DOCKER_REPO:latest
    
    echo '✅ Deployed!'
    sudo docker ps | grep react-app
"
