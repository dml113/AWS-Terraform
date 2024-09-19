#!/bin/bash

# Export
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo =====1-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-app-ec2 --query 'Reservations[].Instances[].InstanceId'
echo

echo =====1-2=====
EC2_SG_ID=$(aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-app-ec2 --query "Reservations[].Instances[].SecurityGroups[].GroupId[]" --output text)
aws ec2 describe-security-groups --group-id $EC2_SG_ID --query "SecurityGroups[].IpPermissions[].FromPort"
aws ec2 describe-security-groups --group-id $EC2_SG_ID --query "SecurityGroups[].IpPermissionsEgress[].FromPort"
echo

echo =====2-1=====
aws configservice describe-config-rules --config-rule-names wsi-config-port --query "ConfigRules[].ConfigRuleName"
echo

echo =====2-2=====
aws configservice get-compliance-details-by-config-rule --config-rule-name wsi-config-port --query "EvaluationResults[].ComplianceType"
echo

echo =====3-1=====
aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '/ec2/deny/port')].logGroupName"
echo

echo =====3-2=====
CW_LOG_STREAM_NAME=$(aws logs describe-log-streams --log-group-name /ec2/deny/port --query "logStreams[].logStreamName" --output text)
EC2_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-app-ec2" --query "Reservations[].Instances[].InstanceId" --output text)
MATCHING_LOG_STREAM_NAME="deny-$EC2_ID"
[ "$CW_LOG_STREAM_NAME" == "$MATCHING_LOG_STREAM_NAME" ] && aws logs describe-log-streams --log-group-name /ec2/deny/port --query "logStreams[].logStreamName"
echo

echo =====4-1=====
EC2_SG_ID=$(aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-app-ec2 --query "Reservations[].Instances[].SecurityGroups[].GroupId[]" --output text)
aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 1234 --cidr 0.0.0.0/0 > /dev/null 2>&1
aws ec2 authorize-security-group-egress --group-id $EC2_SG_ID --protocol tcp --port 4321 --cidr 0.0.0.0/0 > /dev/null 2>&1
sleep 240
aws ec2 describe-security-groups --group-id $EC2_SG_ID --query "SecurityGroups[].IpPermissions[].FromPort"
aws ec2 describe-security-groups --group-id $EC2_SG_ID --query "SecurityGroups[].IpPermissionsEgress[].FromPort"
echo

echo =====4-2=====
date -d "+9 hours" "+%Y-%m-%d %H:%M:%S"
aws logs tail /ec2/deny/port | tail -n 2
echo

echo =====4-3=====
aws configservice get-compliance-details-by-config-rule --config-rule-name wsi-config-port --query "EvaluationResults[].ComplianceType"
echo