pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "your_dockerhub_username/dev"
        DOCKER_PROD_REPO = "your_dockerhub_username/prod"
    }

    stages {

        stage('Checkout Code') {
            steps {
                script {
                    // Detect current branch correctly even if Jenkins is in detached HEAD
                    def branch = sh(
                        script: 'git symbolic-ref --short -q HEAD || git name-rev --name-only HEAD || echo ${GIT_BRANCH}',
                        returnStdout: true
                    ).trim()

                    echo "📦 Branch detected: ${branch}"

                    // Re-checkout the right branch
                    checkout([$class: 'GitSCM',
                              branches: [[name: "*/${branch}"]],
                              userRemoteConfigs: [[url: 'https://github.com/Deepakking07/devops-build.git', credentialsId: 'github-creds']]])

                    env.CURRENT_BRANCH = branch
                }
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🐳 Building Docker image for branch: ${env.CURRENT_BRANCH}"
                    sh "docker build -t ${DOCKER_DEV_REPO}:${env.CURRENT_BRANCH} ."
                }
            }
        }

        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "📤 Pushing Docker image for branch: ${env.CURRENT_BRANCH}"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push ${DOCKER_DEV_REPO}:${CURRENT_BRANCH}
                        '''
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🚀 Deploying to EC2 for production branch: ${env.CURRENT_BRANCH}"
                    // Example deployment step
                    sh 'echo "Deploying application on EC2 instance..."'
                }
            }
        }

        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🩺 Running health check for production environment"
                    // Example health check
                    sh 'echo "Application is running fine."'
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully for branch: ${env.CURRENT_BRANCH}"
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${env.CURRENT_BRANCH}"
        }
    }
}

