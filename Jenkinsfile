// Jenkinsfile
pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'deepakk007'                       // your Docker Hub username
    DEV_REPO = "${DOCKERHUB_USER}/devops-build-dev"
    PROD_REPO = "${DOCKERHUB_USER}/devops-build-prod"
    REMOTE_DIR = "/home/ubuntu/app"
    EC2_IP = '13.221.255.202'                           // your EC2 public IP
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare') {
      steps {
        script {
          BR = env.BRANCH_NAME ?: (env.GIT_BRANCH?.tokenize('/')[-1] ?: 'dev')
          echo "Branch detected: ${BR}"
          IMAGE_TAG = (BR == 'main') ? "${PROD_REPO}:prod-latest" : "${DEV_REPO}:dev-latest"
          echo "Image to build: ${IMAGE_TAG}"
        }
      }
    }

    stage('Build Image') {
      steps {
        sh "docker build -t ${IMAGE_TAG} ."
      }
    }

    stage('Docker Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent(['ec2-ssh-key']) {
          script {
            sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} 'mkdir -p ${REMOTE_DIR}'
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} "cat > ${REMOTE_DIR}/docker-compose.yml <<'YAML'
version: '3.8'
services:
  web:
    image: ${IMAGE_TAG}
    ports:
      - '80:80'
    restart: unless-stopped
YAML"
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} "cd ${REMOTE_DIR} && docker-compose pull || true && docker-compose up -d --remove-orphans"
            """
          }
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh "docker image prune -f || true"
      }
    }
  }

  post {
    success { echo "✅ Pipeline completed successfully for branch ${BR}" }
    failure { echo "❌ Pipeline failed for branch ${BR}" }
  }
}
