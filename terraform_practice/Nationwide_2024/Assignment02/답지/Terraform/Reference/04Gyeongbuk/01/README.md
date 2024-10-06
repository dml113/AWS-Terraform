# README.md

- First !

아래 buildspec.yml,taskdef.json에 AWS_ACCOUNT_ID 변수 지정 부분을 본인 ACCOUNDID로 변경해줍니다.

ACCOUNT_ID 변경이 완료 되었으면 wsi-bastion(중복잇으니 조심)에 /home/ec2-user 경로에 접근합니다.

아래 명령어 실행 전 buildspec.yml과 taskdef.json과 appspec.yml을 추가 후 아래 명령어를 사용하여 Codecommit에 Upload합니다.

============================================================================================
```
/usr/bin/git config --global credential.helper '!aws codecommit credential-helper $@'
/usr/bin/git config --global credential.UseHttpPath true
git clone https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/wsi-commit
sudo mv index.html Dockerfile buildspec.yml buildspec.yml appspec.yml taskdef.json wsi-commit/ 
cd wsi-commit 
git branch -m main
git add -A
git commit -m 'init'
git push origin main
```
============================================================================================
```
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: "ap-northeast-2"
    AWS_ACCOUNT_ID: "<ACCOUNT_ID>"
    ECR_REPO_NAME: "wsi-ecr"
    
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

  build:
    commands:
      - echo Building the Docker image...
      - IMAGE_TAG=$(TZ=$TZ date +"%Y-%m-%d.%H.%M.%S")
      - docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG .

  post_build:
    commands:
      - echo Pushing the Docker image to Amazon ECR...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG
      - printf '{"ImageURI":"%s"}' $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG > imageDetail.json

artifacts:
  files:
      - taskdef.json
      - appspec.yml
      - imageDetail.json
```
============================================================================================
```
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "app"
          ContainerPort: 80
```
============================================================================================
```
{
    "executionRoleArn": "arn:aws:iam::"<ACCOUNT_ID>":role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "app",
            "image": "<IMAGE_NAME>",
            "essential": true,
            "portMappings": [
                {
                    "hostPort":80,
                    "protocol": "tcp",
                    "containerPort": 80
                }
            ]
        }
    ],
    "requiresCompatibilities": [
        "EC2"
    ],
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "family": "wsi-task"
}
```
