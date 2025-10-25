pipeline {
    agent any

    environment {
        // Docker Hub credentials and repos
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"

        // EC2 deployment info
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"  // Replace with your EC2 IP
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    // Detect branch name properly
                    def branchName = env.BRANCH_NAME ?: sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    env.BRANCH_NAME = branchName

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
                        if (env.BRANCH_NAME == 'dev') {
                            echo "📤 Pushing to Dev repo: ${DOCKER_DEV_REPO}"
                            sh """
                                docker tag devops-app:latest ${DOCKER_DEV_REPO}:latest
                                docker push ${DOCKER_DEV_REPO}:latest
                            """
                        } else if (env.BRANCH_NAME == 'main') {
                            echo "📤 Pushing to Prod repo: ${DOCKER_PROD_REPO}"
                            sh """
                                docker tag devops-app:latest ${DOCKER_PROD_REPO}:latest
                                docker push ${DOCKER_PROD_REPO}:latest
                            """
                        } else {
                            echo "⚠️ Unknown branch ${env.BRANCH_NAME}, skipping push."
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { env.BRANCH_NAME == 'main' } // only deploy for main
            }
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
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                echo "✅ Running health check..."
                sh "curl -f http://${EC2_HOST} || echo '⚠️ Health check failed'"
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy successful for ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Build or deploy failed for ${env.BRANCH_NAME}"
        }
    }
}

