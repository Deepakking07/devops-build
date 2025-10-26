pipeline {
    agent any

    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DEV_IMAGE = "deepakk007/devops-build-dev"
        PROD_IMAGE = "deepakk007/devops-build-prod"

        // EC2 deployment details
        EC2_USER = "ec2-user"
        EC2_HOST = "18.234.238.124"
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Set Branch Name') {
            steps {
                script {
                    // Try to get the branch name from common environment variables
                    def gitBranch = env.BRANCH_NAME ?: env.GIT_BRANCH

                    // Fallback for Multi-branch pipeline or specific Git triggers
                    if (!gitBranch && currentBuild?.rawBuild?.getSensitiveBuildVariables()?.get('GIT_BRANCH')) {
                        gitBranch = currentBuild.rawBuild.getSensitiveBuildVariables().get('GIT_BRANCH').replace('origin/', '')
                    }
                    
                    // Final fallback to get the branch from the workspace if a checkout already happened
                    if (!gitBranch) {
                        try {
                            gitBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                        } catch (Exception e) {
                            gitBranch = 'UNKNOWN' // Set a safe default
                        }
                    }

                    // Set the BRANCH_NAME environment variable for the rest of the pipeline
                    env.BRANCH_NAME = gitBranch
                    echo "📦 Detected branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                // Checkout the code for the detected branch
                checkout scm
                echo "📦 Running pipeline for branch: ${env.BRANCH_NAME}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? PROD_IMAGE : DEV_IMAGE
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
                    def imageName = env.BRANCH_NAME == 'main' ? PROD_IMAGE : DEV_IMAGE
                    echo "📤 Pushing Docker image: ${imageName}:latest"
                    sh "docker push ${imageName}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                // Deploy if branch is 'dev' OR 'main'
                expression { env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? PROD_IMAGE : DEV_IMAGE
                    def containerName = env.BRANCH_NAME == 'main' ? "app-main" : "app-dev"
                    // Use 8080:80 for 'dev' branch
                    def portMapping = env.BRANCH_NAME == 'main' ? "80:80" : "8080:80" 

                    echo "🚀 Deploying ${env.BRANCH_NAME} container '${containerName}' on EC2 ${EC2_HOST}"

                    // Ensure to use double quotes for interpolation inside the sh block 
                    // and use the SSH_KEY variable correctly for `ssh -i`
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh """
                            ssh -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} \\
                            'docker pull ${imageName}:latest &&
                            docker stop ${containerName} || true &&
                            docker rm ${containerName} || true &&
                            docker run -d --name ${containerName} -p ${portMapping} ${imageName}:latest'
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            when {
                // Health check if branch is 'dev' OR 'main'
                expression { env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    def port = env.BRANCH_NAME == 'main' ? "80" : "8080"
                    echo "💡 Running health check on ${EC2_HOST}:${port}"
                    sh "curl -f http://${EC2_HOST}:${port} || echo 'Health check failed!'"
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
