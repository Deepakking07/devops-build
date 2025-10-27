pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DEV_IMAGE = "deepakk007/devops-build-dev"
        PROD_IMAGE = "deepakk007/devops-build-prod"

        EC2_USER = "ec2-user"
        EC2_HOST = "54.90.148.128"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    def currentBranch = env.BRANCH_NAME ?: sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    env.ACTUAL_BRANCH = currentBranch
                    echo "📦 Running pipeline for branch: ${env.ACTUAL_BRANCH}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = env.ACTUAL_BRANCH == 'main' ? PROD_IMAGE : DEV_IMAGE
                    echo "🛠️ Building Docker image: ${imageName}:latest"
                    sh "docker build -t ${imageName}:latest ."
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageName = env.ACTUAL_BRANCH == 'main' ? PROD_IMAGE : DEV_IMAGE
                    echo "📤 Pushing Docker image: ${imageName}:latest"
                    sh "docker push ${imageName}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    if (env.ACTUAL_BRANCH in ['dev', 'main']) {
                        def imageName = env.ACTUAL_BRANCH == 'main' ? PROD_IMAGE : DEV_IMAGE
                        def containerName = env.ACTUAL_BRANCH == 'main' ? "app-main" : "app-dev"
                        def portMapping = env.ACTUAL_BRANCH == 'main' ? "80:80" : "8080:80"

                        echo "🚀 Deploying ${env.ACTUAL_BRANCH} container '${containerName}' on EC2 ${EC2_HOST}"

                        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                                ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} \\
                                'docker pull ${imageName}:latest &&
                                 docker stop ${containerName} || true &&
                                 docker rm ${containerName} || true &&
                                 docker run -d --name ${containerName} -p ${portMapping} ${imageName}:latest'
                            """
                        }
                    } else {
                        echo "⚠️ Skipping deployment for branch: ${env.ACTUAL_BRANCH}"
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    if (env.ACTUAL_BRANCH in ['dev', 'main']) {
                        def port = env.ACTUAL_BRANCH == 'main' ? "80" : "8080"
                        echo "💡 Running health check on ${EC2_HOST}:${port}"
                        sh "curl -f http://${EC2_HOST}:${port} || echo 'Health check failed!'"
                    } else {
                        echo "⚠️ Skipping health check for branch: ${env.ACTUAL_BRANCH}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded for branch: ${env.ACTUAL_BRANCH}"
        }
        failure {
            echo "❌ Pipeline failed for branch: ${env.ACTUAL_BRANCH}"
        }
    }
}
