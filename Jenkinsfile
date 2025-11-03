pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCOUNT_ID = '<AWS_ACCOUNT_ID>' // replace
    ECR_REPO = 'my-webapp'
    AWS_CREDENTIALS = 'aws-jenkins-creds' // Jenkins credentials ID
    ECS_CLUSTER = 'my-cluster'
    ECS_SERVICE = 'my-webapp-service'
    ECS_TASK_FAMILY = 'my-webapp-task'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Install & Test') {
      steps {
        sh 'npm ci'
        sh 'npm test'
      }
    }
    stage('Build Docker & Push to ECR') {
      steps {
        script {
          def gitSha = sh(script: 'git rev-parse --short HEAD', returnStdout:true).trim()
          env.IMAGE_TAG = "${gitSha}"
          env.DOCKER_IMAGE = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:env.AWS_CREDENTIALS]]) {
            sh """
              aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com
              aws ecr describe-repositories --repository-names ${env.ECR_REPO} --region ${env.AWS_REGION} || aws ecr create-repository --repository-name ${env.ECR_REPO} --region ${env.AWS_REGION}
              docker build -t ${env.ECR_REPO}:${env.IMAGE_TAG} .
              docker tag ${env.ECR_REPO}:${env.IMAGE_TAG} ${env.DOCKER_IMAGE}:${env.IMAGE_TAG}
              docker tag ${env.ECR_REPO}:${env.IMAGE_TAG} ${env.DOCKER_IMAGE}:latest
              docker push ${env.DOCKER_IMAGE}:${env.IMAGE_TAG}
              docker push ${env.DOCKER_IMAGE}:latest
            """
          }
        }
      }
    }
    stage('Deploy to ECS (Fargate)') {
      steps {
        script {
          env.DOCKER_IMAGE = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
          def taskDef = """
          {
            "family": "${env.ECS_TASK_FAMILY}",
            "networkMode": "awsvpc",
            "executionRoleArn": "arn:aws:iam::${env.AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
            "containerDefinitions":[
              {
                "name":"${env.ECR_REPO}",
                "image":"${env.DOCKER_IMAGE}:${env.IMAGE_TAG}",
                "portMappings":[{"containerPort":8080}],
                "essential":true,
                "logConfiguration":{
                  "logDriver":"awslogs",
                  "options":{
                    "awslogs-group":"/ecs/${env.ECS_TASK_FAMILY}",
                    "awslogs-region":"${env.AWS_REGION}",
                    "awslogs-stream-prefix":"ecs"
                  }
                }
              }
            ],
            "requiresCompatibilities":["FARGATE"],
            "cpu":"256",
            "memory":"512"
          }
          """
          writeFile file:'taskdef.json', text: taskDef
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:env.AWS_CREDENTIALS]]) {
            sh """
              aws ecs register-task-definition --cli-input-json file://taskdef.json --region ${env.AWS_REGION}
              NEW_DEF=$(aws ecs describe-task-definition --task-definition ${env.ECS_TASK_FAMILY} --region ${env.AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text)
              aws ecs update-service --cluster ${env.ECS_CLUSTER} --service ${env.ECS_SERVICE} --task-definition ${NEW_DEF} --region ${env.AWS_REGION}
            """
          }
        }
      }
    }
  }
  post {
    success { echo "SUCCESS: ${env.DOCKER_IMAGE}:${env.IMAGE_TAG}" }
    failure { echo "FAILED" }
  }
}
