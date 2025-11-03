pipeline {
    agent any

    environment {
        AWS_REGION      = 'ap-south-1'
        AWS_ACCOUNT_ID  = '108322181673'
        ECR_REPO_NAME   = 'ci-cd-demo'                // ensure this matches ECR repo name
        IMAGE_TAG       = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh """
                    docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "Logging in to Amazon ECR..."
                withAWS(region: "${AWS_REGION}", credentials: 'aws-ecr-credentials') {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                echo "Tagging and pushing image to ECR..."
                sh """
                    docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Cleanup') {
            steps {
                echo "Cleaning up local Docker images..."
                sh """
                    docker rmi ${ECR_REPO_NAME}:${IMAGE_TAG} || true
                    docker rmi ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} || true
                """
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                    echo "Deploying container to EC2..."

                    ssh -o StrictHostKeyChecking=no ubuntu@43.205.142.131 '
                        aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin 108322181673.dkr.ecr.ap-south-1.amazonaws.com &&
                        sudo docker pull 108322181673.dkr.ecr.ap-south-1.amazonaws.com/myapp:latest || sudo docker pull 108322181673.dkr.ecr.ap-south-1.amazonaws.com/myapp:build-${BUILD_NUMBER} &&
                        sudo docker stop myapp || true &&
                        sudo docker rm myapp || true &&
                        sudo docker run -d -p 80:8080 --name myapp 108322181673.dkr.ecr.ap-south-1.amazonaws.com/myapp:build-${BUILD_NUMBER}
                    '
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build and deploy completed successfully!"
        }
        failure {
            echo "❌ Build failed. Check logs for details."
        }
    }
}
