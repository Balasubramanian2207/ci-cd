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
            sh '''
                aws ecr get-login-password --region ap-south-1 \
                | docker login --username AWS --password-stdin 108322181673.dkr.ecr.ap-south-1.amazonaws.com
                docker push 108322181673.dkr.ecr.ap-south-1.amazonaws.com/ci-cd-demo:build-${BUILD_NUMBER}
            '''
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
