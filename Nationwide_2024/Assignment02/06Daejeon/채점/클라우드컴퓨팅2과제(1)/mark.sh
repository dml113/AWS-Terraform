#!/bin/bash

# Export
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo =====1-1=====
aws dynamodb list-tables --query "TableNames[?@ == 'wsi-table']"
echo

echo =====1-2=====
aws dynamodb describe-table --table-name wsi-table --query "Table.BillingModeSummary.BillingMode"
echo

echo =====2-1=====
aws apigateway get-rest-apis --query "items[?name=='wsi-api'].name"
echo

echo =====2-2=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
aws apigateway get-resources --rest-api-id $API --query "items[?path=='/user'].path"
echo

echo =====2-3=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
aws apigateway get-resources --rest-api-id $API --query "items[?path=='/healthz'].path"
echo

echo =====2-4=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
aws apigateway get-stages --rest-api-id $API --query "item[?stageName=='v1'].stageName"
echo

echo =====3-1=====
aws dynamodb scan --table-name wsi-table \
    --projection-expression "#n" \
    --expression-attribute-names '{"#n": "name"}' \
    --select "SPECIFIC_ATTRIBUTES" \
    --query "Items[].name" \
    --output text | xargs -I {} aws dynamodb delete-item --table-name wsi-table --key "{\"name\": {\"S\": \"{}\"}}"

API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
URL=https://$API.execute-api.ap-northeast-2.amazonaws.com/v1/

curl -sS -X POST -H "Content-Type: application/json" -d '{"name": "skills", "age": 19, "country": "korea"}' $URL/user
echo
echo

echo =====3-2=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
URL=https://$API.execute-api.ap-northeast-2.amazonaws.com/v1/

curl -X GET $URL/user?name=skills
echo
echo

echo =====3-3=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
URL=https://$API.execute-api.ap-northeast-2.amazonaws.com/v1/

curl -X DELETE $URL/user?name=skills
echo
echo

echo =====3-4=====
API=$(aws apigateway get-rest-apis --query "items[?name=='wsi-api'].id" --output text)
URL=https://$API.execute-api.ap-northeast-2.amazonaws.com/v1/

curl -X GET $URL/healthz
echo
echo