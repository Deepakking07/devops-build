pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        DOCKER_PASSWORD = "${DOCKER_HUB_CREDS_PSW}"
        REACT_SERVER_IP = "3.235.191.91"  // YOUR React EC2 IP
        SSH_KEY_PATH = "/var/lib/jenkins/jenkins-key.pem"  // Your key location
    }
    
    triggers {
        pollSCM('H/2 * * * *')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup SSH Key') {
            steps {
                script {
                    sh '''
                        # Copy your jenkins-key.pem to workspace (adjust path if needed)
                        if [ -f "${SSH_KEY_PATH}" ]; then
                            cp ${SSH_KEY_PATH} ./jenkins-key.pem
                            chmod 600 ./jenkins-key.pem
                            echo "✅ SSH key copied to workspace"
                        else
                            echo "❌ SSH key not found at ${SSH_KEY_PATH}"
                            echo "Creating temporary key pair..."
                            ssh-keygen -t rsa -b 4096 -f ./jenkins-key.pem -N "" -q
                        fi
                    '''
                }
            }
        }
        
        stage('Determine Branch') {
            steps {
                script {
                    def detectedBranch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    detectedBranch = detectedBranch?.replaceAll('origin/', '')
                    
                    echo "🌟 Detected branch: ${detectedBranch}"

                    switch(detectedBranch) {
                        case 'dev':
                            env.DOCKER_REPO = 'deepakk007/project3-dev'
                            env.ENVIRONMENT = 'development'
                            break
                        case 'master':
                        case 'main':
                            env.DOCKER_REPO = 'deepakk007/project3-prod'  // YOUR Docker Hub repo
                            env.ENVIRONMENT = 'production'
                            break
                        default:
                            error "❌ Branch '${detectedBranch}' not configured. Use: dev, master, main"
                    }

                    echo "🐳 Docker repo: ${env.DOCKER_REPO}"
                    echo "🏗️ Environment: ${env.ENVIRONMENT}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                        echo "🐳 Building Docker image..."
                        docker build -t ${DOCKER_REPO}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_REPO}:${BUILD_NUMBER} ${DOCKER_REPO}:latest
                        echo "✅ Image built: ${DOCKER_REPO}:latest"
                    '''
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    sh '''
                        echo "🔐 Logging into Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                        
                        echo "📤 Pushing to Docker Hub..."
                        docker push ${DOCKER_REPO}:${BUILD_NUMBER}
                        docker push ${DOCKER_REPO}:latest
                        echo "✅ Pushed to ${DOCKER_REPO}:latest"
                    '''
                }
            }
        }
        
        stage('Deploy to React EC2') {
            steps {
                script {
                    sh '''
                        echo "🚀 Deploying to React server: ${REACT_SERVER_IP}"
                        
                        # SSH to React server and deploy
                        ssh -i ./jenkins-key.pem -o StrictHostKeyChecking=no ubuntu@${REACT_SERVER_IP} "
                            echo '🔄 Stopping existing container...'
                            docker stop react-app || true
                            docker rm react-app || true
                            
                            echo '📥 Pulling latest image...'
                            docker pull ${DOCKER_REPO}:latest
                            
                            echo '🏃 Starting new container...'
                            docker run -d --name react-app -p 80:80 ${DOCKER_REPO}:latest
                            
                            echo '✅ Deployment complete!'
                            docker ps | grep react-app
                        "
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    sh '''
                        echo "🔍 Verifying deployment..."
                        sleep 10
                        curl -f http://${REACT_SERVER_IP} || echo "⚠️ App might still be starting..."
                        echo "✅ Health check complete!"
                    '''
                }
            }
        }
        
        stage('Clean Up') {
            steps {
                sh '''
                    docker image prune -f
                    rm -f ./jenkins-key.pem
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 SUCCESS: ${env.ENVIRONMENT} deployment to ${REACT_SERVER_IP}!"
            echo "🐳 Image: ${env.DOCKER_REPO}:latest"
        }
        failure {
            echo "💥 FAILED: Check logs above"
            emailext (
                to: 'deepakkumark2001@gmail.com',
                subject: "Jenkins Build FAILED: ${env.JOB_NAME} #${BUILD_NUMBER}",
                body: "Check: ${env.BUILD_URL}"
            )
        }
        always {
            echo "🏁 Pipeline finished"
        }
    }
}
