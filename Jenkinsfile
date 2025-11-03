pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '108322181673'
        ECR_REPO_NAME = 'ci-cd-demo'               // your ECR repo name
        IMAGE_TAG = "build-${BUILD_NUMBER}"        // unique image tag for each build

        // Email recipients (add multiple with commas if needed)
        EMAIL_RECIPIENTS = "your_email@gmail.com"
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

        stage('Cleanup Local Images') {
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
                    sh """
                    echo "Deploying container to EC2..."

                    ssh -o StrictHostKeyChecking=no ubuntu@43.205.142.131 '
                        aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com &&
                        sudo docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} &&
                        sudo docker stop myapp || true &&
                        sudo docker rm myapp || true &&
                        sudo docker run -d -p 80:8080 --name myapp ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build, Push, and Deployment completed successfully!"

            // Email notification for success
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>✅ Build and Deployment Successful!</h2>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Deployed to:</b> EC2 Instance (43.205.142.131)</p>
                    <p>Check logs: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br>
                    <p>— Jenkins CI/CD Automation</p>
                """,
                to: "${EMAIL_RECIPIENTS}",
                mimeType: 'text/html'
            )
        }

        failure {
            echo "❌ Pipeline failed. Check the logs for details."

            // Email notification for failure
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>❌ Build or Deployment Failed!</h2>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p>Check logs: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br>
                    <p>— Jenkins CI/CD Automation</p>
                """,
                to: "${EMAIL_RECIPIENTS}",
                mimeType: 'text/html'
            )
        }

        unstable {
            emailext(
                subject: "⚠️ UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>⚠️ Build is Unstable</h2>
                    <p>Some stages may have failed tests or partial deployment.</p>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p>Logs: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br>
                    <p>— Jenkins CI/CD Automation</p>
                """,
                to: "${EMAIL_RECIPIENTS}",
                mimeType: 'text/html'
            )
        }
    }
}
