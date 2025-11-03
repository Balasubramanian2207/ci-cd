pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '108322181673.dkr.ecr.ap-south-1.amazonaws.com/ci-cd-demo'
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Balasubramanian2207/CIA2.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}")
                }
            }
        }

       stage('Push to ECR') {
    steps {
        withAWS(region: 'ap-south-1', credentials: 'aws-ecr-creds') {
            withEnv([
                'AWS_REGION=ap-south-1',
                'ECR_REGISTRY=108322181673.dkr.ecr.ap-south-1.amazonaws.com',
                'IMAGE_NAME=ci-cd-demo'
            ]) {
                sh '''
                    echo "Logging in to Amazon ECR..."
                    aws ecr get-login-password --region $AWS_REGION \
                    | docker login --username AWS --password-stdin $ECR_REGISTRY

                    echo "Pushing image to ECR..."
                    docker push $ECR_REGISTRY/$IMAGE_NAME:build-${BUILD_NUMBER}
                '''
            }
        }
    }
}



        stage('Deploy') {
            steps {
                echo "Deploy stage — you can later add SSH or ECS deploy steps here."
            }
        }
    }
}
