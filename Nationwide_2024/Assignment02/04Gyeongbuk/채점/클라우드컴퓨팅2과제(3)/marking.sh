#!/bin/bash

aws configure set default.region ap-northeast-2

echo =====1-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion \
	--query "Reservations[].Instances[].InstanceType"
echo

echo =====2-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion \
	--query "Reservations[].Instances[].InstanceType"
echo

echo =====3-1=====
APP_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-app" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
curl $APP_PRIVATE_IP:5000/log
echo ""
curl $APP_PRIVATE_IP:5000/healthcheck
echo

echo =====4-1=====
aws opensearch list-domain-names | grep wsi-opensearch
echo

echo =====4-2=====
aws opensearch describe-domain --domain-name wsi-opensearch --query "DomainStatus.ClusterConfig.[InstanceCount, DedicatedMasterCount]"
echo ""
aws opensearch describe-domain --domain-name wsi-opensearch --query "DomainStatus.EngineVersion"
echo ""
OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain --domain-name wsi-opensearch | jq -r '.DomainStatus.Endpoint')
curl -s -u admin:Password01! "https://$OPENSEARCH_ENDPOINT/_cat/indices?index=app-log"
echo ""
OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain --domain-name wsi-opensearch | jq -r '.DomainStatus.Endpoint')
curl -s -u admin:Password01! https://$OPENSEARCH_ENDPOINT/app-log | jq '.["app-log"].mappings.properties | keys[]'
echo ""
echo

echo =====4-3=====
aws opensearch describe-domain --domain-name wsi-opensearch --output json | jq -r '.DomainStatus.Endpoint + "/_dashboards"'
echo "수동채점"
echo