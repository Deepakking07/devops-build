pipeline {
    agent any

    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO  = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        // EC2 deployment details
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"
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
                        if (env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == null) {
                            echo "📤 Pushing to Dev repo: ${DOCKER_DEV_REPO}"
                            sh "docker tag devops-app:latest ${DOCKER_DEV_REPO}:latest"
                            sh "docker push ${DOCKER_DEV_REPO}:latest"
                        } else if (env.BRANCH_NAME == 'main') {
                            echo "📤 Pushing to Prod repo: ${DOCKER_PROD_REPO}"
                            sh "docker tag devops-app:latest ${DOCKER_PROD_REPO}:latest"
                            sh "docker push ${DOCKER_PROD_REPO}:latest"
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when { branch 'main' }  // Only deploy for main (production)
            steps {
                sshagent(['ec2-ssh-key']) {
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
            when { branch 'main' }
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        if [ \$(docker ps -q -f name=devops-app | wc -l) -eq 0 ]; then
                            echo "⚠️ Application is DOWN!"
                            exit 1
                        else
                            echo "✅ Application is running"
                        fi
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & Deploy successful for ${env.BRANCH_NAME ?: 'dev'}"
        }
        failure {
            echo "❌ Build or deploy failed for ${env.BRANCH_NAME ?: 'dev'}"
        }
    }
}

