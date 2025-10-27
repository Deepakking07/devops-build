pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'deepakk007'
        DOCKER_V = '12'
        PROD = 'prod'
    }

    stages {

        // 🧹 Clean workspace before every build
        stage('Clean Workspace') {
            steps {
                echo "Cleaning up old workspace files..."
                deleteDir()
            }
        }

        // 📦 Checkout latest code from GitHub
        stage('Checkout') {
            steps {
                echo "Fetching latest code from GitHub..."
                // Replace with your actual repo & branch
                git branch: 'main', url: 'https://github.com/your-username/your-repo.git'
                
                // Force sync with remote to ensure latest changes
                sh '''
                    git fetch --all
                    git reset --hard origin/main
                    echo "Current Git commit:"
                    git log -1
                '''
            }
        }

        // 🧠 Validation / Pre-checks
        stage('Check') {
            steps {
                script {
                    // List Docker images to verify Docker installation
                    sh 'docker images'
                    // Verify code files
                    sh 'ls -la'
                    echo "CURRENT BRANCH - ${env.GIT_BRANCH}"
                    echo "Environment Variables: ${env}"
                }
            }
        }

        // 🏗️ Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    if (env.GIT_BRANCH == 'origin/master' || env.GIT_BRANCH == 'main') {
                        docker.build("${DOCKER_IMAGE}_${PROD}:${env.BUILD_NUMBER}")
                    } else if (env.GIT_BRANCH == 'origin/dev' || env.GIT_BRANCH == 'dev') {
                        docker.build("${DOCKER_IMAGE}_${env.GIT_BRANCH.split('/')[-1]}:${env.BUILD_NUMBER}")
                    }
                }
            }
        }

        // 🚀 Push Docker Image
        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image for branch ${env.GIT_BRANCH}"
                    docker.withRegistry('https://registry.hub.docker.com','docker_username_paswd') {
                        if (env.GIT_BRANCH == 'origin/master' || env.GIT_BRANCH == 'main') {
                            docker.image("${DOCKER_IMAGE}_${PROD}:${env.BUILD_NUMBER}").push()
                        } else if (env.GIT_BRANCH == 'origin/dev' || env.GIT_BRANCH == 'dev') {
                            docker.image("${DOCKER_IMAGE}_${env.GIT_BRANCH.split('/')[-1]}:${env.BUILD_NUMBER}").push()
                        }
                        echo "Docker image pushed successfully."
                    }
                }
            }
        }

        // 🧩 Run Docker Container (optional in CI)
        stage('Run Docker Container') {
            steps {
                script {
                    echo "Running Docker container..."
                    if (env.GIT_BRANCH == 'origin/master' || env.GIT_BRANCH == 'main') {
                        docker.image("${DOCKER_IMAGE}_${PROD}:${env.BUILD_NUMBER}")
                            .run('-p 80:80')
                    } else if (env.GIT_BRANCH == 'origin/dev' || env.GIT_BRANCH == 'dev') {
                        docker.image("${DOCKER_IMAGE}_${env.GIT_BRANCH.split('/')[-1]}:${env.BUILD_NUMBER}")
                            .run('-p 80:80')
                    }
                }
            }
        }
    }
}
