pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '108322181673'
        ECR_REPO_NAME = 'myapp'   // change this to your ECR repository name
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo 'Logging in to Amazon ECR...'
                withAWS(credentials: 'aws-ecr-creds', region: "${AWS_REGION}") {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    '''
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                echo 'Tagging and pushing image to ECR...'
                sh '''
                    docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up local Docker images...'
                sh '''
                    docker rmi ${ECR_REPO_NAME}:${IMAGE_TAG} || true
                    docker rmi ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} || true
                '''
            }
        }
    }

    post {
        success {
            echo 'Docker image successfully pushed to AWS ECR!'
        }
        failure {
            echo 'Build failed. Check the logs above for details.'
        }
    }
}
