#!/bin/bash

echo ""
echo "===== 1-1-A ====="
aws apigateway get-rest-apis --query items[].name

echo ""
echo "===== 1-2-A ====="
aws dynamodb scan --table-name serverless-user-table --query Items

echo ""
echo "Insert Name: "
read name
echo "===== 1-2-B ====="
apiId=$(aws apigateway get-rest-apis --query items[].id --output text)
curl -sS -w "\n - status code: %{http_code} \n" -X POST "https://$apiId.execute-api.ap-northeast-2.amazonaws.com/v1/user?id=$name&age=19&company=hrdkorea"


echo ""
echo "===== 1-3-A ====="
apiId=$(aws apigateway get-rest-apis --query items[].id --output text)
curl -sS -w "\n - status code: %{http_code} \n" -o /dev/null -X POST "https://$apiId.execute-api.ap-northeast-2.amazonaws.com/v1/user?id=$name-admin&age=19&company=hrdkorea"

echo ""
echo "===== 1-4-A ====="
apiId=$(aws apigateway get-rest-apis --query items[].id --output text)
curl -sS -w "\n - status code: %{http_code} \n" -X GET "https://$apiId.execute-api.ap-northeast-2.amazonaws.com/v1/user?id=$name"

echo ""
echo "===== 1-5-A ====="
apiId=$(aws apigateway get-rest-apis --query "items[?name=='serverless-api-gw'].id" --output text) && resourceId=$(aws apigateway get-resources --rest-api-id $apiId --query "items[?path=='/user'].id" --output text) && aws apigateway get-integration --rest-api-id $apiId --resource-id $resourceId --http-method GET --query "uri" --output text | grep -q 'dynamodb' && echo "DynamoDB integration found" || echo "DynamoDB integration not found"

echo ""
echo "===== 2-1-A ====="
aws dynamodb scan --table-name serverless-user-table --query Items