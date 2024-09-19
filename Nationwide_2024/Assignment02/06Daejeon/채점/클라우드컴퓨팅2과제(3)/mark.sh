#!/bin/bash

# Export
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo =====1-1=====
aws eks describe-cluster --name wsi-eks-cluster --query "cluster.name"
aws eks describe-cluster --name wsi-eks-cluster --query "cluster.version"
echo

echo =====1-2=====
kubectl get ns -o json | jq '.items[] | select(.metadata.name == "wsi-ns") | .metadata.name'
echo

echo =====2-1=====
    aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '/wsi/eks/log/')].logGroupName"
echo

echo =====3-1=====
kubectl get deploy -n wsi-ns -o json | jq '.items[].metadata.name'
echo

echo =====3-2=====
kubectl get po -n wsi-ns -o json | jq '.items[].spec.containers[].name'
echo

echo =====4-1=====
POD_ID=$(kubectl get po -n wsi-ns -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_ID -n wsi-ns -- curl localhost:8080/2xx
kubectl exec -it $POD_ID -n wsi-ns -- curl localhost:8080/3xx
kubectl exec -it $POD_ID -n wsi-ns -- curl localhost:8080/4xx
kubectl exec -it $POD_ID -n wsi-ns -- curl localhost:8080/5xx
kubectl exec -it $POD_ID -n wsi-ns -- curl localhost:8080/healthz
echo

echo =====4-2=====
CW_LOG_STREAM_NAME=$(aws logs describe-log-streams --log-group-name /wsi/eks/log/ --query "logStreams[].logStreamName" --output text)
POD_ID=$(kubectl get po -n wsi-ns -o jsonpath='{.items[0].metadata.name}')
MATCHING_LOG_STREAM_NAME="log-$POD_ID"
[ "$CW_LOG_STREAM_NAME" == "$MATCHING_LOG_STREAM_NAME" ] && aws logs describe-log-streams --log-group-name /wsi/eks/log/ --query "logStreams[].logStreamName"
echo

echo =====4-3=====
aws logs tail /wsi/eks/log/ | tail -n 1 | awk '{print substr($0,index($0,"{"))}' | jq .
echo 