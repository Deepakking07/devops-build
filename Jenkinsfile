pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/dev']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Deepakking07/devops-build.git',
                        credentialsId: 'github-creds'
                    ]]
                ])
            }
        }

        stage('Set Branch Name') {
            steps {
                script {
                    branchName = env.BRANCH_NAME ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "📦 Running pipeline for branch: ${branchName}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = (branchName == 'main') ? "${DOCKER_PROD_REPO}:latest" : "${DOCKER_DEV_REPO}:latest"
                    echo "🛠️ Building Docker image: ${imageName}"
                    sh "docker build -t ${imageName} ."
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                sh "echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin"
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageName = (branchName == 'main') ? "${DOCKER_PROD_REPO}:latest" : "${DOCKER_DEV_REPO}:latest"
                    echo "📤 Pushing Docker image: ${imageName}"
                    sh "docker push ${imageName}"
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { branchName == 'main' }
            }
            steps {
                script {
                    echo "🚀 Deploying to EC2 18.234.238.124..."
                    sh '''
                    ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ubuntu@18.234.238.124 '
                        docker pull ${DOCKER_PROD_REPO}:latest &&
                        docker stop web || true &&
                        docker rm web || true &&
                        docker run -d -p 80:80 --name web ${DOCKER_PROD_REPO}:latest
                    '
                    '''
                }
            }
        }

        stage('Health Check') {
            when {
                expression { branchName == 'main' }
            }
            steps {
                script {
                    echo "🩺 Performing health check..."
                    sh "curl -I http://18.234.238.124"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded for branch: ${branchName}"
        }
        failure {
            echo "❌ Pipeline failed for branch: ${branchName}"
        }
    }
}

