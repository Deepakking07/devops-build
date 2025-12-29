pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        DOCKER_PASSWORD = "${DOCKER_HUB_CREDS_PSW}"
    }
    
    triggers {
        pollSCM('H/2 * * * *')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup SSH Key') {
            steps {
                script {
                    sh '''
                        if [ -f "/var/lib/jenkins/jenkins-key.pem" ]; then
                            cp /var/lib/jenkins/jenkins-key.pem ./jenkins-key.pem
                            chmod 600 ./jenkins-key.pem
                            echo "✅ SSH key copied to workspace"
                        else
                            echo "❌ SSH key not found"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Determine Branch') {
            steps {
                script {
                    def detectedBranch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    detectedBranch = detectedBranch?.replaceAll('origin/', '')
                    
                    echo "🌟 Detected branch: ${detectedBranch}"

                    switch(detectedBranch) {
                        case 'dev':
                            env.DOCKER_REPO = 'deepakk007/project3-dev'
                            env.ENVIRONMENT = 'development'
                            break
                        case 'master':
                        case 'main':
                            env.DOCKER_REPO = 'deepakk007/project3-prod'
                            env.ENVIRONMENT = 'production'
                            break
                        default:
                            env.DOCKER_REPO = 'deepakk007/project3-prod'
                            env.ENVIRONMENT = 'production'
                    }

                    echo "🐳 Docker repository: ${env.DOCKER_REPO}"
                    echo "🏗️ Environment: ${env.ENVIRONMENT}"
                }
            }
        }
        
        stage('Build and Push') {
            steps {
                sh 'chmod +x build.sh && ./build.sh'
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                sh 'chmod +x deploy.sh && ./deploy.sh'
            }
        }
        
        stage('Clean Up') {
            steps {
                sh '''
                    docker images | grep "deepakk007/project3" | awk "{print \$3}" | xargs -r docker rmi || true
                    docker image prune -f || true
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 SUCCESS: ${env.ENVIRONMENT} deployment!"
            echo "🐳 Image: ${env.DOCKER_REPO}:latest"
        }
        failure {
            echo "💥 FAILED: ${env.ENVIRONMENT} deployment!"
        }
        always {
            echo "🏁 Pipeline finished"
        }
    }
}
