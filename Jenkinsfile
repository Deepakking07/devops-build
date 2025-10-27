pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME ?: 'dev'}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Deepakking07/devops-build.git',
                        credentialsId: 'github-creds'
                    ]]
                ])

                script {
                    // Detect branch safely, even in detached HEAD state
                    def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    if (branch == 'HEAD') {
                        branch = env.GIT_BRANCH?.replaceAll(/^origin\\//, '') ?: env.BRANCH_NAME ?: 'unknown'
                    }
                    echo "📦 Running pipeline for branch: ${branch}"
                    env.ACTUAL_BRANCH = branch
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = (env.ACTUAL_BRANCH == 'main') ? "${DOCKER_PROD_REPO}:latest" : "${DOCKER_DEV_REPO}:latest"
                    echo "🛠️ Building Docker image: ${imageName}"
                    sh "docker build -t ${imageName} ."
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                sh '''
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageName = (env.ACTUAL_BRANCH == 'main') ? "${DOCKER_PROD_REPO}:latest" : "${DOCKER_DEV_REPO}:latest"
                    echo "📤 Pushing Docker image: ${imageName}"
                    sh "docker push ${imageName}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    if (env.ACTUAL_BRANCH == 'main') {
                        echo "🚀 Deploying to EC2 for branch: ${env.ACTUAL_BRANCH}"
                        // Add your deployment commands below (example)
                        // sh "ssh -i /path/to/key.pem ubuntu@<EC2-IP> 'docker pull ${DOCKER_PROD_REPO}:latest && docker run -d -p 80:80 ${DOCKER_PROD_REPO}:latest'"
                    } else {
                        echo "⚠️ Skipping deployment for branch: ${env.ACTUAL_BRANCH}"
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    if (env.ACTUAL_BRANCH == 'main') {
                        echo "🩺 Performing health check..."
                        // Add your health check logic here (example)
                        // sh "curl -f http://<EC2-IP> || exit 1"
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

