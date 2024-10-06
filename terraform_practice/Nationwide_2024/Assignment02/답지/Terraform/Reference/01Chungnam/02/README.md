# README.md

- First !
  
아래 명령어를 사용하여 가용영역을 확인해줍니다. (AvailabilityZones.ZoneName[])

  -> aws ec2 describe-availability-zones --region us-west-1
  
현재 modules/01Chungnam/02/wsc2024.vpc.tf 에는 us-west-1a 와 us-west-1b 로 지정되어 있습니다.

명령어 실행 후 결과 값으로 modules/01Chungnam/02/wsc2024.vpc.tf 해당 경로의 resource.aws_default_subnet.default_vpc_subnet_a.availability_zone 부분만 수정합니다.

- Second !
  
아래 buildspec.yml에 AWS_ACCOUNT_ID 변수 지정 부분을 본인 ACCOUNDID로 변경해줍니다.

/home/ec2-user/buildspec.yml 에 경로에 아래 buildspec.yml 추가 후 codecommit에 아래 명령어를 사용하여 Upload 해줍니다.


===================================================================================
```
rm -f /home/ec2-user/Dockerfile
/usr/bin/git config --global credential.helper '!aws codecommit credential-helper $@'
/usr/bin/git config --global credential.UseHttpPath true
git clone https://git-codecommit.us-west-1.amazonaws.com/v1/repos/wsc2024-cci
cd wsc2024-cci
sudo mv /home/ec2-user/* .
git branch -m master
git add -A
git commit -m 'init'
git push origin master
```

===================================================================================

```
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: "us-west-1"
    AWS_ACCOUNT_ID: "211125622661" # 변경 
    ECR_REPO_NAME: "wsc2024-repo"
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - echo -n "F" >> Dockerfile ; echo -n "R" >> Dockerfile ; echo -n "O" >> Dockerfile ; echo -n "M" >> Dockerfile ; echo " python:3.12-alpine" >> Dockerfile
      - echo "WORKDIR /app/" >> Dockerfile
      - echo -n "C" >> Dockerfile ; echo -n "O" >> Dockerfile ; echo -n "P" >> Dockerfile ; echo -n "Y" >> Dockerfile ; echo " . ." >> Dockerfile
      - echo "RUN pip install -r requirements.txt" >> Dockerfile
      - echo "RUN apk update" >> Dockerfile
      - echo "RUN apk add curl" >> Dockerfile
      - echo -n "C" >> Dockerfile ; echo -n "M" >> Dockerfile ; echo -n "D" >> Dockerfile ; echo '["python3", "main.py"]' >> Dockerfile

  build:
    commands:
      - echo Building the Docker image...
      - IMAGE_TAG=$(echo $CODEBUILD_BUILD_ID | cut -d':' -f2)
      - docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG .

  post_build:
    commands:
      - echo Pushing the Docker image to Amazon ECR...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG
      - echo Creating imagedefinitions.json file...
      - printf '[{"name":"example","imageUri":"%s"}]' "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG" > imagedefinitions.json
      - cat imagedefinitions.json 

artifacts:
  files:
    - imagedefinitions.json
```
