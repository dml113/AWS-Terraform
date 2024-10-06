#!/bin/bash

# 환경 변수 설정
export DistributionID="<Cloudfront_Distribution_ID>"
export AP_BUCKET="ap-wsi-static-<4words>"
export US_BUCKET="us-wsi-static-<4words>"
export CF_DOMAIN=$(aws cloudfront get-distribution --id ${DistributionID} --query "Distribution.DomainName" --output text)

# 채점

# 6-6
echo "----- 6-6 -----"
aws secretsmanager rotate-secret --secret-id $(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `rds!`)].Name' --output text)
sleep 2m
aws secretsmanager get-secret-value --secret-id $(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `rds!`)].Name' --output text) --query "SecretString" --output text | jq -r .password
kubectl exec -n wsi -it $(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep customer | head -n 1) -- /bin/sh -c 'echo $MYSQL_PASSWORD' 
kubectl exec -n wsi -it $(kubectl get pods -n wsi --no-headers -o custom-columns=":metadata.name" | grep product | head -n 1) -- /bin/sh -c 'echo $MYSQL_PASSWORD'
echo "---------------"

# 10-4
echo "----- 10-4 -----"
aws s3 rm s3://$AP_BUCKET/index.html
export InvalidationID=$(aws cloudfront create-invalidation --distribution-id ${DistributionID} --paths "/index.html" --query "Invalidation.Id" --output text)
aws cloudfront wait invalidation-completed --distribution-id ${DistributionID} --id ${InvalidationID}
curl --silent -o /dev/null -X GET --max-time 5 -w "%{http_code}\n" https://${CF_DOMAIN}/index.html
echo "---------------"

# 10-5
echo "----- 10-5 -----"
aws s3 rm s3://$US_BUCKET/index.html
export InvalidationID=$(aws cloudfront create-invalidation --distribution-id ${DistributionID} --paths "/index.html" --query "Invalidation.Id" --output text)
aws cloudfront wait invalidation-completed --distribution-id ${DistributionID} --id ${InvalidationID}
curl --silent -o /dev/null -X GET --max-time 5 -w "%{http_code}\n" https://${CF_DOMAIN}/index.html
echo "---------------"