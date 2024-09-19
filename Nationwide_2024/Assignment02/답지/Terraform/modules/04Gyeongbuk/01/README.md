ssh 접근 후에 /home/ec2-user에 buildspec.yml 파일을 만들고 아래와 같은 내용을 넣는다.
자신이 설정한 값들의 수정이 필요하다.

version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: "ap-northeast-2"
    AWS_ACCOUNT_ID: "226347592148" <-------------------------------- 수정 --------------------------                      
    ECR_REPO_NAME: "wsi-ecr"

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:latest .

  post_build:
    commands:
      - echo Pushing the Docker image to Amazon ECR...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:latest
      - echo Creating imagedefinitions.json file...
      - printf '[{"name":"app","imageUri":"%s"}]' "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME:latest" > imagedefinitions.json
      - cat imagedefinitions.json 

artifacts:
  files:
    - imagedefinitions.json

아래와 같은 명령어를 입력하면 된다. 

/usr/bin/git config --global credential.helper '!aws codecommit credential-helper $@'
/usr/bin/git config --global credential.UseHttpPath true
git clone https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/wsi-commit
sudo mv index.html Dockerfile buildspec.yml wsi-commit/ 
cd wsi-commit 
git branch -m main
git add -A
git commit -m 'init'
git push origin main