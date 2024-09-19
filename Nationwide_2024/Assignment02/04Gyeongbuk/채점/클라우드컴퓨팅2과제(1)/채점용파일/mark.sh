#!/bin/bash

##### 24년 전국 2과제 CI/CD 채점 스크립트

echo ----- 1-1 -----		# CodeCommit Repo 구성
aws codecommit get-repository --repository-name wsi-commit --query "repositoryMetadata.repositoryName"
echo


echo ----- 1-2 -----		# CodeCommit Branch 구성
aws codecommit get-repository --repository-name wsi-commit --query "repositoryMetadata.defaultBranch"
echo


echo ----- 2-1 -----		# CodeBuild 구성
aws codebuild batch-get-projects --names wsi-build --query "projects[*].name"
echo


echo ----- 3-1 -----		# CodePipeline 구성
aws codepipeline get-pipeline --name wsi-pipeline --query "pipeline.stages[*].[name, actions[*].actionTypeId.provider]"
echo


echo ----- 4-1 -----		# ALB 생성 확인
aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[].LoadBalancerName"
echo


echo ----- 4-2 -----		# ALB Scheme 확인
aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[].Scheme"


echo ----- 5-1 -----		# 동작 테스트
aws elbv2 describe-load-balancers --name wsi-alb --query "LoadBalancers[].DNSName"
echo

# 5-1 및 5-2 는 채점기준표 확인