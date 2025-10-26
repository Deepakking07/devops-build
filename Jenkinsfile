pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = "deepakk007/devops-build-dev"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    // Determine branch name
                    BRANCH_NAME = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "📦 Checked out branch: ${BRANCH_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    sh "docker build -t app-image:${BRANCH_NAME} ."
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    echo "🔐 Logging in to DockerHub..."
                    sh """
                        echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "📤 Pushing image to ${DOCKER_REPO}:${BRANCH_NAME}"
                    sh """
                        docker tag app-image:${BRANCH_NAME} ${DOCKER_REPO}:${BRANCH_NAME}
                        docker push ${DOCKER_REPO}:${BRANCH_NAME}
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { BRANCH_NAME == "main" }
            }
            steps {
                script {
                    echo "🚀 Deploying to EC2 for branch: ${BRANCH_NAME}"
                    // Add your SSH or deployment commands here
                }
            }
        }

        stage('Health Check') {
            when {
                expression { BRANCH_NAME == "main" }
            }
            steps {
                echo "🔍 Running Health Check for Production..."
                // Add curl or health endpoint check commands here
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded for branch: ${BRANCH_NAME}"
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${BRANCH_NAME}"
        }
    }
}

