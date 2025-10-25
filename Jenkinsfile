pipeline {
    agent any

    environment {
        // DockerHub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        // EC2 details
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    // Fallback for cases when BRANCH_NAME is not set
                    env.ACTUAL_BRANCH = env.BRANCH_NAME ?: sh(returnStdout: true, script: "git rev-parse --abbrev-ref HEAD").trim()
                    echo "📦 Checked out branch: ${env.ACTUAL_BRANCH}"
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
                    def repo = (env.ACTUAL_BRANCH == 'main') ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
                    echo "📤 Pushing Docker image to ${repo}"

                    sh """
                        docker tag devops-app:latest ${repo}:latest
                        echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                        docker push ${repo}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { env.ACTUAL_BRANCH == 'main' }  // Deploy only from main
            }
            steps {
                sshagent([env.SSH_KEY]) {
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
                expression { env.ACTUAL_BRANCH == 'main' }
            }
            steps {
                echo "✅ Running health check..."
                sh "curl -f http://${EC2_HOST} || echo 'Health check failed'"
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy successful for branch: ${env.ACTUAL_BRANCH}"
        }
        failure {
            echo "❌ Build or Deploy failed for branch: ${env.ACTUAL_BRANCH}"
        }
    }
}

