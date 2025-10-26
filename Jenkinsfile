pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = "${DOCKERHUB_CREDENTIALS_USR}"
        DOCKERHUB_PASSWORD = "${DOCKERHUB_CREDENTIALS_PSW}"
        DEV_REPO = "deepakking07/devops-build-dev"
        PROD_REPO = "deepakking07/devops-build-prod"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    // Detect branch name even in detached HEAD
                    env.BRANCH_NAME = env.GIT_BRANCH?.replaceFirst(/^origin\//, '') ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "📦 Checked out branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    sh "docker build -t app-image:${env.BRANCH_NAME} ."
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    echo "🔐 Logging in to DockerHub..."
                    sh """
                        echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def repo = (env.BRANCH_NAME == 'main') ? PROD_REPO : DEV_REPO
                    echo "📤 Pushing image to ${repo}:${env.BRANCH_NAME}"
                    sh """
                        docker tag app-image:${env.BRANCH_NAME} ${repo}:${env.BRANCH_NAME}
                        docker push ${repo}:${env.BRANCH_NAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build and push successful for branch: ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${env.BRANCH_NAME ?: 'unknown'}"
        }
    }
}

