#!/bin/bash

# 환경 변수 설정
export DistributionID="<Cloudfront_Distribution_ID>"
export AP_BUCKET="ap-wsi-static-<4words>"
export US_BUCKET="us-wsi-static-<4words>"
export CF_DOMAIN=$(aws cloudfront get-distribution --id ${DistributionID} --query "Distribution.DomainName" --output text)

# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
export InvalidationID=$(aws cloudfront create-invalidation --distribution-id ${DistributionID} --paths "/*" --query "Invalidation.Id" --output text)
aws cloudfront wait invalidation-completed --distribution-id ${DistributionID} --id ${InvalidationID}
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 -----"
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsi-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-app-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-app-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-b --query "Subnets[0].CidrBlock"
echo "---------------"

# 1-2
echo "----- 1-2 -----"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-app-a-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-app-b-rt --query "RouteTables[].Routes[].NatGatewayId"  | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-public-rt --query "RouteTables[].Routes[]" | grep "igw-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-data-rt --query "RouteTables[].Routes[]" | grep -E "igw-|nat-" | wc -l
echo "---------------"

# 1-3
echo "----- 1-3 -----"
aws ec2 describe-vpc-endpoints --query "VpcEndpoints[].ServiceName"
echo "---------------"

# 1-4
echo "----- 1-4 -----"
aws ec2 describe-flow-logs --query "FlowLogs[].LogGroupName"
echo "---------------"

# 2-1
echo "----- 2-1 -----"
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[0].Instances[0].InstanceType"
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text | cut -d '/' -f 2
echo "---------------"

# 2-2
echo "----- 2-2 -----"
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName" \
; aws ec2 describe-security-groups --filter Name=group-name,Values=wsi-bastion-sg --query "SecurityGroups[0].IpPermissions[].{FromPort:FromPort,ToPort:ToPort,IpRanges:IpRanges}"
echo "---------------"

# 3-1
echo "----- 3-1 -----"
aws dynamodb describe-table --table-name order --query "Table.{KeySchema:KeySchema[?KeyType=='HASH'],SSEType:SSEDescription.SSEType,BillingMode:BillingModeSummary.BillingMode}"
echo "---------------"

# 3-2
echo "----- 3-2 -----"
aws dynamodb describe-continuous-backups --table-name order --query "ContinuousBackupsDescription.ContinuousBackupsStatus"
echo "---------------"

# 4-1
echo "----- 4-1 -----"
aws rds describe-db-instances --db-instance-identifier wsi-rds-mysql --query "DBInstances[0].{Engine:Engine,MultiAZ:MultiAZ,DBInstanceStatus:DBInstanceStatus,DBInstanceClass:DBInstanceClass,StorageEncrypted:StorageEncrypted,EnabledCloudwatchLogsExports:EnabledCloudwatchLogsExports,Port:Endpoint.Port}"
echo "---------------"

# 4-2
echo "----- 4-2 -----"
aws ec2 describe-security-groups --group-ids $(aws rds describe-db-instances --db-instance-identifier wsi-rds-mysql --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" --output text) --query "SecurityGroups[0].IpPermissions[].UserIdGroupPairs[0].GroupId"
echo "---------------"

# 5-1
echo "----- 5-1 -----"
aws ecr describe-repositories --repository-names "customer" "product" "order" --query "repositories[].{imageTagMutability:imageTagMutability,scanOnPush:imageScanningConfiguration.scanOnPush,encryptionConfiguration:encryptionConfiguration.encryptionType}"
echo "---------------"

# 5-2
echo "----- 5-2 -----"
aws ecr describe-registry --query "replicationConfiguration.rules[0].destinations[0].region"
echo "---------------"

# 6-1
echo "----- 6-1 -----"
aws eks describe-cluster --name wsi-eks-cluster --query "cluster.{version:version,endpointPublicAccess:resourcesVpcConfig.endpointPublicAccess,endpointPrivateAccess:resourcesVpcConfig.endpointPrivateAccess,logging:logging,encryption:encryptionConfig[0].resources}"
echo "---------------"

# 6-2
echo "----- 6-2 -----"
aws eks describe-nodegroup --cluster-name wsi-eks-cluster --nodegroup-name wsi-addon-nodegroup --query "nodegroup.{instanceType:instanceTypes[0],amiType:amiType}"; kubectl get no -l "eks.amazonaws.com/nodegroup=wsi-addon-nodegroup" --output json | jq ".items[].metadata.labels | .\"eks.amazonaws.com/nodegroup\" + \" \" + .\"topology.kubernetes.io/zone\"";
echo "---------------"

# 6-3
echo "----- 6-3 -----"
aws eks describe-nodegroup --cluster-name wsi-eks-cluster --nodegroup-name wsi-app-nodegroup --query "nodegroup.{instanceType:instanceTypes[0],amiType:amiType}"; kubectl get no -l "eks.amazonaws.com/nodegroup=wsi-app-nodegroup" --output json | jq ".items[].metadata.labels | .\"eks.amazonaws.com/nodegroup\" + \" \" + .\"topology.kubernetes.io/zone\"";
echo "---------------"

# 6-4
echo "----- 6-4 -----"
aws eks describe-fargate-profile --cluster-name wsi-eks-cluster --fargate-profile-name wsi-app-fargate --query "fargateProfile.{namespace:selectors[0].namespace,status:status}"
echo "---------------"

# 6-5
echo "----- 6-5 -----"
kubectl exec -n wsi -it $(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep customer | head -n 1) -- curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --max-time 10
echo "---------------"

# 6-7
echo "----- 6-7 -----"
kubectl describe pod -n wsi $(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep customer | head -n 1) | grep QoS
echo "---------------"

# 7-1
echo "----- 7-1 -----"
curl $(aws elbv2 describe-load-balancers --query "LoadBalancers[0].DNSName" --output text) --max-time 10
echo "---------------"

# 8-1
echo "----- 8-1 -----"
aws s3api get-bucket-encryption --bucket $AP_BUCKET --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm"
aws s3api get-bucket-encryption --bucket $US_BUCKET --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm"
echo "---------------"

# 8-2
echo "----- 8-2 -----"
aws s3api get-bucket-policy --bucket $AP_BUCKET --query "Policy" --output text | jq .Statement[].Principal.Service
aws s3api get-bucket-policy --bucket $US_BUCKET --query "Policy" --output text | jq .Statement[].Principal.Service
echo "---------------"

# 8-3
echo "----- 8-3 -----"
echo "----- 8-3 -----"
echo "WorldSkills" > sample.txt
aws s3api put-object --bucket $AP_BUCKET --key sample.txt --body sample.txt

while true; do
  metadata=$(aws s3api head-object --bucket $AP_BUCKET --key sample.txt)
  replication_status=$(echo "$metadata" | jq -r '.ReplicationStatus')

  if [[ "$replication_status" == "COMPLETED" ]]; then
    echo 1
    break
  elif [[ "$replication_status" == "PENDING" ]]; then
    echo "Replication status: $replication_status. Checking again in 30 seconds..."
    sleep 30
  else
    echo 0
    break
  fi
done
echo "---------------"

# 9-1
echo "----- 9-1 -----"
aws cloudfront list-tags-for-resource --resource "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/${DistributionID}" --query "Tags.Items[?Key=='Name']"; aws cloudfront get-distribution --id ${DistributionID} --query "Distribution.DistributionConfig.{PriceClass:PriceClass,IsIPV6Enabled:IsIPV6Enabled}"
echo "---------------"

# 9-2
echo "----- 9-2 -----"
for i in {1..5}; do curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/index.html | grep -iE "x-cache:|^200$"; done
echo "---------------"

# 9-3
echo "----- 9-3 -----"
curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" http://${CF_DOMAIN}/index.html | grep -iE "x-cache:|^301$"
echo "---------------"

# 10-1 ~ 10-3
echo "----- 10-1 ~ 10-3 -----"
echo ${CF_DOMAIN}/index.html
echo "인터넷 브라우저로 채점"
echo "---------------"

# 11-1
echo "----- 11-1 -----"
id=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
curl --silent --output /dev/null "https://${CF_DOMAIN}/v1/customer?id=${id}"
curl --silent --output /dev/null "https://${CF_DOMAIN}/v1/product?id=${id}"
curl --silent --output /dev/null "https://${CF_DOMAIN}/v1/order?id=${id}"
sleep 1m
aws logs filter-log-events --log-group-name /wsi/webapp/customer --filter-pattern "\"/v1/customer?id=${id}\"" | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/product --filter-pattern "\"/v1/product?id=${id}\"" | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/order --filter-pattern "\"/v1/order?id=${id}\"" | jq ".events | length"
echo "---------------"

# 11-2
echo "----- 11-2 -----"
aws logs filter-log-events --log-group-name /wsi/webapp/customer --filter-pattern '"/healthcheck"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/product --filter-pattern '"/healthcheck"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/order --filter-pattern '"/healthcheck"' | jq ".events | length"
echo "---------------"

# 12-1
echo "----- 12-1 -----"
echo "AWS CloudWatch 콘솔에서 채점"
echo "---------------"