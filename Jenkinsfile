pipeline {
    agent any

    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        // EC2 deployment details
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"  // Replace with your EC2 public IP
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {

        stage('Checkout Code') {
            steps {
                script {
                    def branchName = env.BRANCH_NAME ?: "dev"
                    echo "📦 Checking out branch: ${branchName}"
                    git branch: branchName,
                        url: 'https://github.com/Deepakking07/devops-build.git',
                        credentialsId: 'github-creds'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🛠️ Building Docker image..."
                sh 'docker build -t devops-app:latest .'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-credentials') {
                        def branchName = env.BRANCH_NAME ?: "dev"
                        if (branchName == 'main') {
                            echo "📤 Pushing to Production repo: ${DOCKER_PROD_REPO}"
                            sh """
                                docker tag devops-app:latest ${DOCKER_PROD_REPO}:latest
                                docker push ${DOCKER_PROD_REPO}:latest
                            """
                        } else {
                            echo "📤 Pushing to Dev repo: ${DOCKER_DEV_REPO}"
                            sh """
                                docker tag devops-app:latest ${DOCKER_DEV_REPO}:latest
                                docker push ${DOCKER_DEV_REPO}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                branch 'main'
            }
            steps {
                echo "🚀 Deploying to EC2..."
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin &&
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
                branch 'main'
            }
            steps {
                echo "🩺 Checking application health..."
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        if ! curl -s http://localhost:80 > /dev/null; then
                            echo "⚠️ Application is DOWN!"
                            exit 1
                        else
                            echo "✅ Application is running successfully."
                        fi
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & Deploy successful for branch: ${env.BRANCH_NAME ?: 'dev'}"
        }
        failure {
            echo "❌ Build or Deploy failed for branch: ${env.BRANCH_NAME ?: 'dev'}"
        }
    }
}

