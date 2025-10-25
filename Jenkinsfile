pipeline {
    agent any

    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_DEV_REPO = "deepakk007/devops-build-dev"
        DOCKER_PROD_REPO = "deepakk007/devops-build-prod"
<<<<<<< HEAD
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"
        SSH_KEY = credentials('ec2-ssh-key')
=======

        // EC2 deployment details
        EC2_USER = "ubuntu"
        EC2_HOST = "3.95.63.76"  // Replace with your EC2 IP
        SSH_KEY = credentials('ec2-ssh-key')

        // Force branch detection for Jenkins
        BRANCH_NAME = "${env.BRANCH_NAME ?: 'dev'}"
>>>>>>> main
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
<<<<<<< HEAD
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
=======
                    def branch = env.BRANCH_NAME
                    echo "📦 Checking out branch: ${branch}"

                    git branch: branch,
                        url: 'https://github.com/Deepakking07/devops-build.git',
                        credentialsId: 'github-creds'
>>>>>>> main
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
<<<<<<< HEAD
                    def repo = env.CURRENT_BRANCH == 'main' ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
                    echo "📤 Pushing Docker image to ${repo}"
=======
                    def repo = env.BRANCH_NAME == 'main' ? env.DOCKER_PROD_REPO : env.DOCKER_DEV_REPO
                    echo "📤 Pushing Docker image to ${repo}"

>>>>>>> main
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
<<<<<<< HEAD
                expression { return env.CURRENT_BRANCH == 'main' }
=======
                expression { env.BRANCH_NAME == 'main' }  // deploy only for main
>>>>>>> main
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
<<<<<<< HEAD
                expression { return env.CURRENT_BRANCH == 'main' }
            }
            steps {
                echo "✅ Deployment successful! Running health check..."
=======
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                echo "✅ Running health check..."
>>>>>>> main
                sh "curl -f http://${EC2_HOST} || echo 'Health check failed'"
            }
        }
    }

    post {
        success {
<<<<<<< HEAD
            echo "🎉 Build & Deploy successful for branch: ${env.CURRENT_BRANCH}"
=======
            echo "🎉 Build & deploy successful for branch: ${env.BRANCH_NAME}"
>>>>>>> main
        }
        failure {
            echo "❌ Build or deploy failed for branch: ${env.BRANCH_NAME}"
        }
    }
}

