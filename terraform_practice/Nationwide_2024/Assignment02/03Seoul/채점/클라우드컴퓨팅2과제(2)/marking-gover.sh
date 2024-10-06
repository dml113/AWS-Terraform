#!/bin/bash

# 환경 변수 설정
export instance_name=wsi-test
export sg_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" --query "Reservations[].Instances[].SecurityGroups[].GroupId" --output json | jq -r '.[0]')
export instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-test" --query "Reservations[].Instances[].InstanceId" --output json | jq -r '.[0]')
export vpc_id=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[].Instances[].VpcId" --output json | jq -r '.[0]')
# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 (3분 소요)-----"
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
sleep 180
aws ec2 describe-security-groups --group-ids $sg_id --query "SecurityGroups[].IpPermissions[]" | jq '.[] | select(.ToPort == 443)'

# 1-2
echo "----- 1-2 (3분 소요)-----"
export new_sg_id=$(aws ec2 create-security-group --group-name last --description "New security group" --vpc-id $vpc_id --output text)
aws ec2 authorize-security-group-ingress --group-id $new_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $new_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
sleep 180
aws ec2 describe-security-groups --group-ids $new_sg_id --query "SecurityGroups[].IpPermissions[]" | jq '.[] | select(.ToPort == 22)'

# 1-3
echo "----- 1-3 (3분 소요)-----"
aws ec2 modify-instance-attribute --instance-id $instance_id --groups $new_sg_id
sleep 180
aws ec2 describe-security-groups --group-ids $new_sg_id --query "SecurityGroups[].IpPermissions[]" | jq '.[] | select(.ToPort == 443)'

# 1-4
echo "----- 1-4 -----"
aws ec2 describe-security-groups --group-ids $sg_id --query "SecurityGroups[].IpPermissions[].ToPort" | jq '.[]'