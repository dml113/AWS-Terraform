#!/bin/bash

# 환경 변수 설정
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 -----"
aws iam list-users --query "Users[?UserName=='tester']" | grep -i username
echo "---------------"

# 1-2
echo "----- 1-2 -----"
aws iam list-attached-user-policies --user-name tester | grep AdministratorAccess
echo "---------------"

# 1-3
echo "----- 1-3 -----"
aws iam get-policy-version --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query "Account" --output text):policy/mfaBucketDeleteControl --version-id v1 --query 'PolicyVersion.Document.Statement[].Condition' | jq
echo "---------------"

# 1-4
echo "----- 1-4 -----"
aws iam list-groups --query "Groups[?GroupName=='user_group_kr']" | grep GroupName
echo "---------------"

# 1-5
echo "----- 1-5 -----"
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::$ACCOUNT_ID:user/tester \
    --action-names ec2:DescribeInstances \
    --region ap-northeast-2 | jq '.EvaluationResults[0].EvalDecision'
echo "---------------"