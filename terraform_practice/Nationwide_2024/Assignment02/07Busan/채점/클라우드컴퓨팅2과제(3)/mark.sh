#!/bin/bash

# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 -----"
aws codecommit list-repositories --query "repositories[].repositoryName" \
; aws codecommit list-branches --repository-name wsi-repo
echo "---------------"

# 2-1
echo "----- 2-1 -----"
aws codebuild list-projects \
; aws ecr describe-repositories --repository-names wsi-ecr --query "repositories[].repositoryName"
echo "---------------"

# 3-1
echo "----- 3-1 -----"
aws deploy list-applications \
; aws deploy list-deployment-groups --application-name wsi-app \
; aws deploy get-deployment-group --application-name wsi-app --deployment-group-name wsi-dg --query "deploymentGroupInfo.deploymentStyle.deploymentType"
echo "---------------"

# 4-1
echo "----- 4-1 -----"
aws codepipeline get-pipeline --name wsi-pipeline --query "pipeline.name"
echo "---------------"

# 4-2
echo "----- 4-2 -----"
aws codepipeline get-pipeline --name wsi-pipeline --query "pipeline.stages[].name"
echo "---------------"