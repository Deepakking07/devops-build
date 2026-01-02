pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        DOCKER_PASSWORD = "${DOCKER_HUB_CREDS_PSW}"
        EC2_HOST = '3.235.191.91'
        EC2_USER = 'ec2-user'
    }
    
    triggers {
        pollSCM('H/2 * * * *')  // Checks every 2 min
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out from GitHub...'
                checkout scm
            }
        }
        
        stage('Setup SSH Key') {
            steps {
                sh '''
                    if [ -f "/var/lib/jenkins/jenkins-key.pem" ]; then
                        cp /var/lib/jenkins/jenkins-key.pem ./jenkins-key.pem
                        chmod 600 ./jenkins-key.pem
                        echo "✅ SSH key ready"
                    else
                        echo "❌ Copy jenkins-key.pem to /var/lib/jenkins/"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Detect Branch & Select Repo') {
            steps {
                script {
                    def branch = env.BRANCH_NAME ?: sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    branch = branch.replaceAll('origin/', '')
                    
                    echo "🌟 Branch: ${branch}"
                    
                    if (branch == 'dev') {
                        env.DOCKER_REPO = "${DOCKER_USERNAME}/project3-dev"
                        env.ENVIRONMENT = 'DEVELOPMENT'
                        env.DEPLOY_TARGET = 'skip'
                    } else {
                        env.DOCKER_REPO = "${DOCKER_USERNAME}/project3-prod"
                        env.ENVIRONMENT = 'PRODUCTION'
                        env.DEPLOY_TARGET = 'live'
                    }
                    
                    def timestamp = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
                    env.IMAGE_TAG = "${timestamp}"
                    env.FULL_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
                    env.LATEST_IMAGE = "${DOCKER_REPO}:latest"
                    
                    echo "🐳 Repo: ${DOCKER_REPO}"
                    echo "🏷️  Full: ${FULL_IMAGE}"
                    echo "🌐 Env: ${ENVIRONMENT}"
                }
            }
        }
        
        stage('Docker Login') {
            steps {
                sh '''
                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                    echo "✅ Logged into Docker Hub"
                '''
            }
        }
        
        stage('Build Image') {
            steps {
                sh '''
                    docker build -t ${FULL_IMAGE} .
                    docker tag ${FULL_IMAGE} ${LATEST_IMAGE}
                    echo "✅ Built ${FULL_IMAGE}"
                '''
            }
        }
        
        stage('Push Image') {
            steps {
                sh '''
                    docker push ${FULL_IMAGE}
                    docker push ${LATEST_IMAGE}
                    echo "✅ Pushed to ${DOCKER_REPO}"
                '''
            }
        }
        
        stage('Deploy to EC2') {
            when {
                expression { env.DEPLOY_TARGET == 'live' }
            }
            steps {
                sh '''
                    ssh -i jenkins-key.pem -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                        docker pull ${LATEST_IMAGE}
                        docker stop react-app || true
                        docker rm react-app || true
                        docker run -d --name react-app --restart always -p 80:80 ${LATEST_IMAGE}
                        docker image prune -f
                        echo \"✅ Deployed on EC2!\"
                    "
                '''
            }
        }
        
        stage('Health Check') {
            when {
                expression { env.DEPLOY_TARGET == 'live' }
            }
            steps {
                sh '''
                    sleep 15
                    if curl -f -m 10 http://${EC2_HOST}; then
                        echo "✅ LIVE: http://${EC2_HOST} - 200 OK!"
                    else
                        echo "❌ Health check failed"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Cleanup') {
            steps {
                sh '''
                    docker logout
                    docker rmi $(docker images -q ${DOCKER_USERNAME}/project3*) 2>/dev/null || true
                    rm -f jenkins-key.pem
                    docker image prune -f
                    echo "🧹 Workspace cleaned"
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 ${ENVIRONMENT} SUCCESS!"
            echo "🐳 ${FULL_IMAGE}"
            echo "🔗 Dev: https://hub.docker.com/r/${DOCKER_USERNAME}/project3-dev/tags"
            echo "🔗 Prod: https://hub.docker.com/r/${DOCKER_USERNAME}/project3-prod/tags"
        }
        failure {
            echo "💥 ${ENVIRONMENT} FAILED!"
        }
        always {
            echo "🏁 Pipeline complete: ${BUILD_URL}"
        }
    }
}
