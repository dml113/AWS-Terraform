#!/bin/bash

# set default region of aws cli
aws configure set default.region ap-northeast-2


echo ----- 1-1 -----
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsi-vpc --query "Vpcs[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-app-a --query "Subnets[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-app-b --query "Subnets[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-a --query "Subnets[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-b --query "Subnets[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-a --query "Subnets[0].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-b --query "Subnets[0].CidrBlock"
echo


echo ----- 1-2 -----
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-app-a-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-app-b-rt --query "RouteTables[].Routes[].NatGatewayId"  | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-public-rt --query "RouteTables[].Routes[]" | grep "igw-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-data-rt --query "RouteTables[].Routes[]" | grep -E "igw-|nat-" | wc -l
echo


echo ----- 1-3 -----
aws ec2 describe-vpc-endpoints --query "VpcEndpoints[].ServiceName"
echo


echo ----- 2-1 -----
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[0].Instances[0].InstanceType"
echo


echo ----- 2-2 -----
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName"
aws ec2 describe-security-groups --filter Name=group-name,Values=wsi-bastion-sg --query "SecurityGroups[0].IpPermissions[].{FromPort:FromPort,ToPort:ToPort,IpRanges:IpRanges}"
echo


echo ----- 3-1 -----
aws rds describe-db-clusters --db-cluster-identifier wsi-aurora-mysql --query 'DBClusters[*].{DBClusterIdentifier: DBClusterIdentifier, EngineVersion: EngineVersion, Encryption: StorageEncrypted, LogExports: EnabledCloudwatchLogsExports}' --output json
aws rds describe-db-clusters --db-cluster-identifier wsi-aurora-mysql --query 'DBClusters[*].KmsKeyId' --output text

echo


echo ----- 4-1 -----
aws dynamodb describe-table --table-name order --query 'Table.{TableName: TableName, EncryptionAtRest: SSEDescription.SSEType}' --output json
aws dynamodb describe-table --table-name order --query 'Table.SSEDescription.KMSMasterKeyArn' --output text
echo

# get cdn DNSname
export cdn=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=wsi-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)

echo ----- 5-1 -----
curl -X POST "https://${cdn}/v1/customer" -H "Content-Type: application/json" -H "user-agent: safe-client" -d \
'{
	"id": "123",
	"name": "wsiman",
	"gender": "man"
}'
echo
curl -X GET "https://${cdn}/v1/customer?id=123" -H "Content-Type: application/json" -H "user-agent: safe-client"
echo
echo


echo ----- 5-2 -----
curl -X POST "https://${cdn}/v1/product" -H "Content-Type: application/json" -H "user-agent: safe-client" -d \
'{
	"id": "123",
	"name": "wsiman",
	"category": "book"
}'
echo
curl -X GET "https://${cdn}/v1/product?id=123" -H "Content-Type: application/json" -H "user-agent: safe-client"
echo
echo


echo ----- 5-3 -----
curl -X POST "https://${cdn}/v1/order" -H "Content-Type: application/json" -H "user-agent: safe-client" -d \
'{
	"id": "123",
	"customerid": "123",
	"productid": "123"
}'
echo
curl -X GET "https://${cdn}/v1/order?id=123" -H "Content-Type: application/json" -H "user-agent: safe-client"
echo
echo


echo ----- 6-1 -----
aws secretsmanager describe-secret --secret-id customer --query 'Name' --output text
aws secretsmanager describe-secret --secret-id product --query 'Name' --output text
aws secretsmanager describe-secret --secret-id order --query 'Name' --output text
echo


echo ----- 7-1 -----
aws ecr describe-images --repository-name customer-ecr --query "imageDetails[].imageTags[]"
aws ecr describe-images --repository-name product-ecr --query "imageDetails[].imageTags[]"
aws ecr describe-images --repository-name order-ecr --query "imageDetails[].imageTags[]"

aws ecr describe-image-scan-findings --repository-name customer-ecr --image-id imageTag=latest --query "imageScanFindings.findingSeverityCounts"
aws ecr describe-image-scan-findings --repository-name product-ecr --image-id imageTag=latest --query "imageScanFindings.findingSeverityCounts" 
aws ecr describe-image-scan-findings --repository-name order-ecr --image-id imageTag=latest --query "imageScanFindings.findingSeverityCounts"
echo


echo ----- 8-1 -----
aws eks describe-nodegroup --cluster-name wsi-eks-cluster --nodegroup-name wsi-app-nodegroup --query "nodegroup.nodegroupName"
aws eks describe-nodegroup --cluster-name wsi-eks-cluster --nodegroup-name wsi-addon-nodegroup --query "nodegroup.nodegroupName"
kubectl get nodes --no-headers -l eks.amazonaws.com/nodegroup=wsi-app-nodegroup | wc -l
kubectl get nodes --no-headers -l eks.amazonaws.com/nodegroup=wsi-addon-nodegroup | wc -l
kubectl get no -l "eks.amazonaws.com/nodegroup=wsi-app-nodegroup" --output json | jq ".items[].metadata.labels.\"node.kubernetes.io/instance-type\""
kubectl get no -l "eks.amazonaws.com/nodegroup=wsi-addon-nodegroup" --output json | jq ".items[].metadata.labels.\"node.kubernetes.io/instance-type\""
echo


echo ----- 8-2 -----
kubectl get pods -n wsi --no-headers -l app=customer | wc -l
kubectl get pods -n wsi --no-headers -l app=product | wc -l
kubectl get pods -n wsi --no-headers -l app=order | wc -l
kubectl get pods -n wsi -l app=order -o jsonpath="{.items[0].spec.nodeName}"
echo

# get alb DNSname
albDNS=$(aws elbv2 describe-load-balancers --name wsi-app-alb --output text --query "LoadBalancers[].DNSName")

echo ----- 9-1 -----
curl -s -o /dev/null -w "%{http_code}" -X GET http://${albDNS}/v1/customer?id=123 -H "X-wsi-header: Skills2024" --max-time 5
echo


echo ----- 10-1 -----
aws s3 ls | grep -E "apne2-wsi-static"
echo


echo ----- 10-2 -----
aws s3api get-bucket-encryption --bucket $(aws s3 ls | grep apne2-wsi-static | awk '{print $3}') --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm'
echo


# get cdn DNSname
export cdn=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=wsi-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
	
echo ----- 11-1 -----
curl -X GET "https://${cdn}/v1/customer?id=123" -H "Content-Type: application/json" -H "user-agent: safe-client"
echo


echo ----- 11-2 -----
curl -X GET "https://${cdn}/static/index.html" -H "Content-Type: application/json" -H "user-agent: safe-client"
echo


echo ----- 12-1 -----
aws logs describe-log-groups --log-group-name-prefix /wsi/webapp/customer --query 'logGroups[*].kmsKeyId' --output text
aws logs describe-log-groups --log-group-name-prefix /wsi/webapp/product --query 'logGroups[*].kmsKeyId' --output text
aws logs describe-log-groups --log-group-name-prefix /wsi/webapp/order --query 'logGroups[*].kmsKeyId' --output text
echo


echo ----- 12-2 -----
curl --silent --output /dev/null -X GET "https://${cdn}/v1/customer?id=skills2024" -H "Content-Type: application/json" -H "user-agent: safe-client"
curl --silent --output /dev/null -X GET "https://${cdn}/v1/product?id=skills2024" -H "Content-Type: application/json" -H "user-agent: safe-client"
curl --silent --output /dev/null -X GET "https://${cdn}/v1/order?id=skills2024" -H "Content-Type: application/json" -H "user-agent: safe-client"
sleep 1m
aws logs filter-log-events --log-group-name /wsi/webapp/customer --filter-pattern '"/v1/customer?id=skills2024"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/product --filter-pattern '"/v1/product?id=skills2024"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/order --filter-pattern '"/v1/order?id=skills2024"' | jq ".events | length"
echo


echo ----- 12-3 -----
aws logs filter-log-events --log-group-name /wsi/webapp/customer --filter-pattern '"/healthcheck"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/product --filter-pattern '"/healthcheck"' | jq ".events | length"
aws logs filter-log-events --log-group-name /wsi/webapp/order --filter-pattern '"/healthcheck"' | jq ".events | length"
echo



echo ----- 13-1 -----
pod=$(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep product| head -n 1)
kubectl exec -it $pod -n wsi -- curl -X GET --max-time 5 -w "\n%{http_code}\n" customer-service.wsi.svc.cluster.local/v1/customer

pod=$(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep customer | head -n 1)
kubectl exec -it $pod -n wsi -- curl -X GET --max-time 5 -w "\n%{http_code}\n" product-service.wsi.svc.cluster.local/v1/product
echo


# get alb DNSname
albDNS=$(aws elbv2 describe-load-balancers --name wsi-app-alb --output text --query "LoadBalancers[].DNSName")

# get alb ID
albID=$(aws ec2 describe-security-groups --filter Name=group-name,Values=wsi-app-alb-sg --query "SecurityGroups[0].GroupId" | sed s/\"//g)

echo ----- 13-2 -----
curl -X GET -H 'X-wsi-header: Skills2024' --max-time 5 -w "\n%{http_code}\n" http://${albDNS}/v1/product
echo


echo ----- 13-3 -----

# 포트 전체개방
aws ec2 authorize-security-group-ingress --group-id $albID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $albID --protocol tcp --port 80 --cidr 0.0.0.0/0

curl -X GET --max-time 5 -w "\n%{http_code}\n" http://${albDNS}/v1/product
curl -X GET -H 'X-wsi-header: Skills2024' --max-time 5 -w "\n%{http_code}\n" http://${albDNS}/v1/product
echo


# get cdn DNSname
export cdn=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=wsi-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)

echo ----- 13-4 -----
curl -X GET -A safe-client --max-time 5 -w "\n%{http_code}\n" https://${cdn}/static/index.html
curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${cdn}/static/index.html
echo

