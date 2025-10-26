pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76" // Replace with your EC2 IP
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    echo "📦 Checked out branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🛠️ Building Docker image..."
                    sh "docker build -t devops-app:latest ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def repo = (env.BRANCH_NAME == 'main') ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
                    echo "📤 Pushing Docker image to ${repo}"

                    sh """
                        docker tag devops-app:latest ${repo}:latest
                        echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS --password-stdin
                        docker push ${repo}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                sshagent([SSH_KEY]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u deepakk007 --password-stdin &&
                        docker pull ${DOCKER_PROD_REPO}:latest &&
                        docker stop devops-app || true &&
                        docker rm devops-app || true &&
                        docker run -d -p 80:80 --name devops-app ${DOCKER_PROD_REPO}:latest
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    echo "✅ Running health check..."
                    sh "curl -f http://${EC2_HOST} || echo 'Health check failed'"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Build & deploy successful for branch: ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${env.BRANCH_NAME}"
        }
    }
}

