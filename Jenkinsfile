pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')  // Your Docker Hub credentials ID
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"
        EC2_USER = "ubuntu"
        EC2_HOST = "13.221.255.202"
        SSH_KEY = credentials('ec2-ssh-key')  // Your EC2 SSH key credentials ID
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: env.BRANCH_NAME ?: 'dev', url: 'https://github.com/Deepakking07/devops-build.git', credentialsId: 'github-creds'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    IMAGE_TAG = (env.BRANCH_NAME == 'main') ? "${DOCKER_PROD_REPO}:latest" : "${DOCKER_DEV_REPO}:latest"
                    sh "docker build -t ${IMAGE_TAG} ."
                }
            }
        }

        stage('Push to DockerHub') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                }
            }
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        sh "docker push ${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                branch 'main'
            }
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                    docker pull ${DOCKER_PROD_REPO}:latest &&
                    docker stop app || true &&
                    docker rm app || true &&
                    docker run -d -p 80:80 --name app ${DOCKER_PROD_REPO}:latest
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & Deploy successful for ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Build failed for ${env.BRANCH_NAME}"
        }
    }
}

