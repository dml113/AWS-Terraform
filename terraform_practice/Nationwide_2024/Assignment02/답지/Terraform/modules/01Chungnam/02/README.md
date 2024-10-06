# 1
# /home/ec2-user/buildspec.yml에 아래와 같은 내용을 넣어준다.

version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: "us-west-1"
    AWS_ACCOUNT_ID: "226347592148" # 변경 ------------------------------------------------------------------------------------------------------------------------------
    ECR_REPO_NAME: "wsc2024-repo"

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - echo "FROM python:3.12-alpine" > Dockerfile
      - echo "WORKDIR /app/" >> Dockerfile
      - echo "COPY . ." >> Dockerfile
      - echo "RUN pip install -r requirements.txt" >> Dockerfile
      - echo "RUN apk update" >> Dockerfile
      - echo "RUN apk add curl" >> Dockerfile
      - echo 'CMD ["python3", "main.py"]' >> Dockerfile

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

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 2 

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