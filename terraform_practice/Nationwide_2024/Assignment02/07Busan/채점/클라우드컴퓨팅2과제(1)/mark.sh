 #!/bin/bash

# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 -----"
echo "" ;aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wsi-project-vpc" --query "Vpcs[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; echo "" ;aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-project-priv-a" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-project-pub-b" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-project-pub-a" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-project-priv-b" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; echo "" ;aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=wsi-project-*" --query "InternetGateways[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text; echo "" \
; echo "" ;aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=wsi-project-nat-b" --query "NatGateways[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
; aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=wsi-project-nat-a" --query "NatGateways[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text; echo "" \
; echo "" ;aws ec2 describe-route-tables --filters "Name=tag:Name,Values=wsi-project-priv-a-rt" --query "RouteTables[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
;aws ec2 describe-route-tables --filters "Name=tag:Name,Values=wsi-project-pub-rt" --query "RouteTables[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text \
;aws ec2 describe-route-tables --filters "Name=tag:Name,Values=wsi-project-priv-b-rt" --query "RouteTables[*].{Name:Tags[?Key=='Name'].Value | [0]}" --output text
echo "---------------"

# 2-1
echo "----- 2-1 -----"
aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-project-ec2" --query "Reservations[*].Instances[*].[InstanceId, InstanceType, IamInstanceProfile.Arn]" --output text \
 | awk '{print $1,$2,$3}' \
 | xargs -I {} bash -c 'INSTANCE_PROFILE_NAME=$(echo {} | awk -F"/" "{print \$NF}"); ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query "InstanceProfile.Roles[*].RoleName" --output text) \
 ; echo "Instance ID: $(echo {} | awk "{print \$1}")"; echo "Instance Type: $(echo {} | awk "{print \$2}")" \
 ; aws iam list-attached-role-policies --role-name $ROLE_NAME --query "AttachedPolicies[*].[PolicyName, PolicyArn]" --output text' 
echo "---------------"

# 3-1
echo "----- 3-1 -----"
aws iam list-users --query "Users[?starts_with(UserName, 'wsi-project-user')].UserName" --output json
echo "---------------"

# 4-2
echo "----- 3-2A -----"
echo "아래 정보로 AWS 콘솔로 접속합니다."
echo "$IAM_USER1 정보:"
echo "계정 ID(12자리): $ACCOUNT_ID"
echo "사용자 이름: $IAM_USER1"
echo "암호: <설정 한 사용자 암호>"
echo "---------------"

read -p "3-2A 다하셨나요? 3-2B로 진행하겠습니까? (y/n): " user_input

# Check the user's input
if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
    
    # 3-2B
    echo "----- 3-2B -----"
    echo "아래 정보로 AWS 콘솔로 접속합니다."
    echo "$IAM_USER2 정보:"
    echo "계정 ID(12자리): $ACCOUNT_ID"
    echo "사용자 이름: $IAM_USER2"
    echo "암호: <설정 한 사용자 암호>"
    echo "---------------"
else
    echo "다시 하기..."
    exit 1
fi