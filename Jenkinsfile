pipeline {
    agent any

    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        // EC2 deployment details
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"  // Replace with your EC2 IP
        SSH_KEY = credentials('ec2-ssh-key')

        // Force branch detection for Jenkins
        BRANCH_NAME = "${env.BRANCH_NAME ?: 'dev'}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    def branch = env.BRANCH_NAME
                    echo "📦 Checking out branch: ${branch}"

                    git branch: branch,
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
                    def repo = env.BRANCH_NAME == 'main' ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
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
                expression { env.BRANCH_NAME == 'main' }  // deploy only for main
            }
            steps {
                sshagent([env.SSH_KEY]) {
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
                echo "✅ Running health check..."
                sh "curl -f http://${EC2_HOST} || echo 'Health check failed'"
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

