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
                        if [ -f "/var/lib/jenkins/jenkins-key.pem" ]; then
                            cp /var/lib/jenkins/jenkins-key.pem ./jenkins-key.pem
                            chmod 600 ./jenkins-key.pem
                            echo "✅ SSH key copied"
                        else
                            echo "❌ SSH key missing - check /var/lib/jenkins/"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Determine Branch & Repo') {
            steps {
                script {
                    def branch = env.BRANCH_NAME ?: sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    branch = branch.replaceAll('origin/', '')
                    
                    echo "🌟 Branch detected: ${branch}"
                    
                    if (branch == 'dev') {
                        env.DOCKER_REPO = "${DOCKER_USERNAME}/project3-dev"
                        env.ENVIRONMENT = 'development'
                    } else {
                        env.DOCKER_REPO = "${DOCKER_USERNAME}/project3-prod"
                        env.ENVIRONMENT = 'production'
                    }
                    
                    def timestamp = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
                    env.IMAGE_TAG = "${timestamp}"
                    env.FULL_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
                    env.LATEST_IMAGE = "${DOCKER_REPO}:latest"
                    
                    echo "🐳 Repo: ${env.DOCKER_REPO}"
                    echo "🏷️  Tag: ${env.FULL_IMAGE}"
                }
            }
        }
        
        stage('Docker Login') {
            steps {
                sh '''
                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                    echo "✅ Docker Hub login successful"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${FULL_IMAGE} .
                    docker tag ${FULL_IMAGE} ${LATEST_IMAGE}
                    echo "✅ Built ${FULL_IMAGE}"
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                sh """
                    docker push ${FULL_IMAGE}
                    docker push ${LATEST_IMAGE}
                    echo "✅ Pushed to ${DOCKER_REPO}"
                """
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                sh """
                    ssh -i jenkins-key.pem -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                        docker pull ${LATEST_IMAGE}
                        docker stop react-app || true
                        docker rm react-app || true
                        docker run -d --name react-app -p 80:80 ${LATEST_IMAGE}
                        docker image prune -f
                    "
                    echo "✅ Deployed ${LATEST_IMAGE} to ${ENVIRONMENT}"
                """
            }
        }
        
        stage('Health Check') {
            steps {
                sh """
                    sleep 10
                    if curl -f http://${EC2_HOST}; then
                        echo "✅ Health check PASSED - App LIVE!"
                    else
                        echo "❌ Health check FAILED"
                        exit 1
                    fi
                """
            }
        }
        
        stage('Clean Up') {
            steps {
                sh '''
                    docker logout
                    docker rmi $(docker images -q deepakk007/project3*) 2>/dev/null || true
                    rm -f jenkins-key.pem
                    echo "🧹 Cleanup complete"
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 ${ENVIRONMENT.toUpperCase()} DEPLOYMENT SUCCESS!"
            echo "🐳 Images: ${FULL_IMAGE} & ${LATEST_IMAGE}"
            echo "🌐 Live: http://${EC2_HOST}"
        }
        failure {
            echo "💥 ${ENVIRONMENT.toUpperCase()} DEPLOYMENT FAILED!"
            emailext (
                to: 'your-email@example.com',
                subject: "Jenkins FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Check: ${env.BUILD_URL}"
            )
        }
        always {
            echo "🏁 Pipeline complete"
        }
    }
}
