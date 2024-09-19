echo -e "========1-1-A========"
kubectl get crd | grep argoproj.io | awk {'print $1'} \
; curl $(kubectl get ingress -n app | grep blue-green-ingress | awk {'print $4'})

echo -e "\n========1-2-A========"
echo "작업 수행"

echo -e "\n========1-3-A========"
kubectl argo rollouts get rollout blue-green-app -n app | egrep "Strategy" \
; kubectl argo rollouts get rollout blue-green-app -n app | egrep "stable" |grep "Healthy" | awk {'print $6,$8'}