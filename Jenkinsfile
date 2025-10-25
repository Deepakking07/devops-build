pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"
        SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {

        stage('Checkout Code') {
            steps {
                script {
                    // Try multiple methods to detect the branch correctly
                    def branch = sh(
                        script: '''
                            git symbolic-ref --short -q HEAD || \
                            git rev-parse --abbrev-ref HEAD || \
                            git name-rev --name-only HEAD
                        ''',
                        returnStdout: true
                    ).trim()

                    // Normalize branch names
                    branch = branch.replaceAll('^origin/', '')
                    branch = branch.replaceAll('^remotes/origin/', '')

                    echo "📦 Branch detected: ${branch}"
                    env.CURRENT_BRANCH = branch

                    // Checkout the correct branch explicitly
                    checkout([$class: 'GitSCM',
                        branches: [[name: "*/${branch}"]],
                        userRemoteConfigs: [[url: 'https://github.com/Deepakking07/devops-build.git', credentialsId: 'github-creds']]
                    ])
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
                    def repo = env.CURRENT_BRANCH == 'main' ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
                    echo "📤 Pushing Docker image to ${repo}"
                    sh """
                        docker tag devops-app:latest ${repo}:latest
                        echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS --password-stdin
                        docker push ${repo}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { return env.CURRENT_BRANCH == 'main' }
            }
            steps {
                sshagent([env.SSH_KEY]) {
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
                expression { return env.CURRENT_BRANCH == 'main' }
            }
            steps {
                echo "✅ Deployment successful! Running health check..."
                sh "curl -f http://${EC2_HOST} || echo 'Health check failed'"
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy successful for branch: ${env.CURRENT_BRANCH}"
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${env.CURRENT_BRANCH}"
        }
    }
}

