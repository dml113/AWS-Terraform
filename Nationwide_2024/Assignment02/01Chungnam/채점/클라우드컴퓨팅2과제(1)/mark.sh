#!/bin/bash
echo ================ 1-1 =====================
aws iam list-users --query "Users[?UserName=='Admin'].UserName"
aws iam list-users --query "Users[?UserName=='Employee'].UserName"

echo ================ 1-2 =====================
aws iam list-attached-user-policies --user-name Admin 
aws iam list-attached-user-policies --user-name Employee

echo ================ 1-3 =====================
aws iam get-role --role-name wsc2024-instance-role --query 'Role.RoleName'

echo ================ 1-4 =====================
aws iam list-attached-role-policies --role-name wsc2024-instance-role --query "AttachedPolicies[].PolicyArn"

echo ================ 2-1 =====================
aws cloudtrail describe-trails --trail-name-list wsc2024-CT --query "trailList[].Name"

echo ================ 2-2 =====================
aws cloudwatch describe-alarms --alarm-name-prefix wsc2024-gvn-alarm --query 'MetricAlarms[*].AlarmName'

echo ================ 2-3 =====================
aws logs describe-log-groups --log-group-name-prefix wsc2024-gvn-LG --query 'logGroups[].logGroupName' --output text

echo ================ 3-1 ===================== 
aws lambda list-functions --query "Functions[?FunctionName=='wsc2024-gvn-Lambda'].FunctionName"

echo ================ 4-1 ===================== 
USERNAME="Employee"
CREATED_KEYS=$(aws iam create-access-key --user-name "$USERNAME")
ACCESS_KEY_ID=$(echo "$CREATED_KEYS" | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$CREATED_KEYS" | jq -r '.AccessKey.SecretAccessKey')
aws configure set aws_access_key_id "$ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"
sleep 10
aws iam attach-role-policy --role-name wsc2024-instance-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
rm -rf ~/.aws/*
timeout 180 bash -c 'while [ "$(aws cloudwatch describe-alarms --alarm-names "wsc2024-gvn-alarm" --query "MetricAlarms[0].StateValue" --output text)" != "ALARM" ]; do echo "Waiting for alarm to enter ALARM state..."; sleep 30; done; echo "Alarm is now in ALARM state."'

echo ================ 4-2 =====================
aws iam list-attached-role-policies --role-name wsc2024-instance-role

echo ================ 5-1 =====================
USERNAME="Admin"
CREATED_KEYS=$(aws iam create-access-key --user-name "$USERNAME")
ACCESS_KEY_ID=$(echo "$CREATED_KEYS" | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$CREATED_KEYS" | jq -r '.AccessKey.SecretAccessKey')
aws configure set aws_access_key_id "$ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"

sleep 10
aws iam attach-role-policy --role-name wsc2024-instance-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
sleep 180 && aws cloudwatch describe-alarms --alarm-names "wsc2024-gvn-alarm" --query "MetricAlarms[0].StateValue" --output text

echo ================ 5-2 =====================
aws iam list-attached-role-policies --role-name wsc2024-instance-role