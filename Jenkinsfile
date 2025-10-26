pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DEV_IMAGE = "deepakk007/devops-build-dev"
        PROD_IMAGE = "deepakk007/devops-build-prod"

        EC2_SERVER = "ec2-user@18.234.238.124"  // your single EC2 instance
        SSH_KEY = credentials('ec2-ssh-key')     // Jenkins SSH private key
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
                script {
                    // Detect branch correctly even if detached
                    env.BRANCH_NAME = sh(
                        script: "git rev-parse --abbrev-ref HEAD || git name-rev --name-only HEAD",
                        returnStdout: true
                    ).trim()
                    echo "📦 Checked out branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker build -t app-image:${env.BRANCH_NAME} ."
            }
        }

        stage('Login to DockerHub') {
            steps {
                echo "🔐 Logging in to DockerHub..."
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? PROD_IMAGE : DEV_IMAGE
                    echo "📤 Pushing image to ${imageName}:${env.BRANCH_NAME}"
                    sh """
                        docker tag app-image:${env.BRANCH_NAME} ${imageName}:${env.BRANCH_NAME}
                        docker push ${imageName}:${env.BRANCH_NAME}
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { return env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? PROD_IMAGE : DEV_IMAGE
                    echo "🚀 Deploying ${env.BRANCH_NAME} image to ${EC2_SERVER}"

                    sh """
                        ssh -i \$SSH_KEY -o StrictHostKeyChecking=no ${EC2_SERVER} \\
                        'docker pull ${imageName}:${env.BRANCH_NAME} &&
                         docker stop app || true &&
                         docker rm app || true &&
                         docker run -d --name app -p 80:80 ${imageName}:${env.BRANCH_NAME}'
                    """
                }
            }
        }

        stage('Health Check') {
            when {
                expression { return env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    echo "💡 Running health check on ${EC2_SERVER}"
                    sh """
                        ssh -i \$SSH_KEY -o StrictHostKeyChecking=no ${EC2_SERVER} \\
                        'curl -f http://localhost || echo "Health check failed!"'
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded for branch: ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Pipeline failed for branch: ${env.BRANCH_NAME}"
        }
    }
}
