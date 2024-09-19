#!/bin/bash

aws configure set default.region ap-northeast-2

echo -e '\n'
echo === 1-1 ===
curl -s http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token | jq

echo -e '\n'
echo === 1-2 ===
curl -s http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token/none | jq

echo -e '\n'
echo === 2-1 ===
aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-2 | jq '.WebACLs | length'

echo -e '\n'
echo === 2-2 ===
WAFNAME=$(aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-2 --query "WebACLs[?Name=='wsi-waf'].Name" --output text)
WAFID=$(aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-2 --query "WebACLs[?Name=='wsi-waf'].Id" --output text)
aws wafv2 get-web-acl --scope REGIONAL --name $WAFNAME --id $WAFID --region ap-northeast-2 | jq '.WebACL.Rules | length'

echo -e '\n'
echo === 3-1 ===
TOKEN=$(curl -s http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token | jq -r '.token')

curl -H "Authorization: $TOKEN" http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token/verify

echo -e '\n'
echo === 3-2 ===
TOKEN2=$(curl -s http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token/none | jq -r '.token')

curl -H "Authorization: $TOKEN2" http://$(aws elbv2 describe-load-balancers --names wsi-alb --query "LoadBalancers[0].DNSName" --output text)/v1/token/verify

echo -e '\n'