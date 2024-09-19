#!/bin/sh

echo "1-1"
aws ec2 describe-vpcs --filters Name=tag:Name,Values=gm-vpc --region ap-northeast-2 --query "Vpcs[0].Tags[?Key=='Name'].Value"

echo "1-2"
aws ec2 describe-vpcs --filters Name=tag:Name,Values=gm-vpc --region ap-northeast-2 --query "Vpcs[0].VpcId" --output text | \
xargs -I {} aws ec2 describe-subnets --filters Name=vpc-id,Values={} --region ap-northeast-2 --query "Subnets[].Tags[?Key=='Name'].Value[]" --output text

echo "1-3"
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=gm-vpc" --query "Vpcs[0].VpcId" --output text) --region ap-northeast-2

echo "1-4"
aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.ap-northeast-2.s3"

echo "1-5"
aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.ap-northeast-2.dynamodb"

echo "------------------------------------------------------------------------"

echo "2-1"
aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text --region ap-northeast-2

echo "2-2"
aws ec2 describe-instances --filters Name=tag:Name,Values=gm-bastion --query "Reservations[*].Instances[*].InstanceType" --output text --region ap-northeast-2

echo "2-3"
aws ec2 describe-instances --filters Name=tag:Name,Values=gm-bastion --query "Reservations[*].Instances[*].SubnetId" --output text --region ap-northeast-2 | \
xargs -I {} aws ec2 describe-subnets --subnet-ids {} --query "Subnets[*].Tags" --output json --region ap-northeast-2

echo "2-4"
ROLE_NAME=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=gm-bastion" --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text --region ap-northeast-2 | cut -d '/' -f2)
POLICY_ARNS=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[*].PolicyArn" --output text --region ap-northeast-2)
for POLICY_ARN in $POLICY_ARNS; do
  VERSION_ID=$(aws iam get-policy --policy-arn "$POLICY_ARN" --query "Policy.DefaultVersionId" --output text --region ap-northeast-2)
  POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION_ID" --query "PolicyVersion.Document" --output json --region ap-northeast-2)
  if echo "$POLICY_DOCUMENT" | grep -q '"Effect": "Allow"' && echo "$POLICY_DOCUMENT" | grep -q '"Action": "*"' && echo "$POLICY_DOCUMENT" | grep -q '"Resource": "*"'; then
    echo "Fail"
  else
    echo "Success"
  fi
done

echo "2-5"
echo "수동 채점 필요 (gm-bastion에서 실행)"

echo "2-6"
echo "수동 채점 필요 (gm-bastion에서 실행)"
aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'gm-alb')].DNSName" 

echo "2-7"
echo "수동 채점 필요 (gm-bastion에서 실행)"
aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'gm-alb')].DNSName" 

echo "2-8"
aws elbv2 describe-tags --resource-arns $(aws elbv2 describe-target-groups --names gm-tg --query "TargetGroups[*].TargetGroupArn" --output text --region ap-northeast-2) --region ap-northeast-2 --query "TagDescriptions[*].Tags[?Key=='Name'].Value[]" --output text

echo "2-9 ~ 2-10"
aws elbv2 describe-load-balancers --names gm-alb --region ap-northeast-2 --query "LoadBalancers[?Scheme!='None'].[LoadBalancerName,Scheme,Tags[?Key=='Name'].Value[] | [0] || '']" --output table
echo "------------------------------------------------------------------------"

echo "3-1"
aws s3api list-buckets --query "Buckets[*].Name" --output text | xargs -I {} sh -c 'echo "Bucket: {}" && aws s3api get-bucket-tagging --bucket {} --query "TagSet[?Key==\`Name\`].Value" --output text 2>/dev/null'

echo "3-2"
echo "수동 채점 필요 (gm-bastion에서 실행)"
aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'gm-alb')].DNSName" 
echo "------------------------------------------------------------------------"

echo "4-1"
aws dynamodb list-tags-of-resource --resource-arn $(aws dynamodb describe-table --table-name gm-db --query "Table.TableArn" --output text --region ap-northeast-2) --region ap-northeast-2 --query "Tags[?Key=='Name'].Value" --output text
