# README.md

- 주의사항
01. S3 Console에서 apne2-wsi-static-<비번호> 생성이 되는 지 확인을 합니다. (생성이 되지않는 경우에는 질의를 넣습니다.)
02. 다음과 같은 순으로 Terraform apply 진행합니다. terraform init -> terraform apply --auto-approve 

     (apply 시 설정하는 변수 지정부분에 비번호 입력합니다.)
03. CloudFront,보안구성 외 전부 자동화 입니다. (../notion.txt 경로에 잇는 주소를 확인합니다.)
04. Terraform apply 가 완료된 후에는 Console로 이동하여 CloudFormation 부분에 EKS가 생성되기를 대기합니다.

    (1시간이내에 EKS까지가 정상입니다.)


05. EKS 생성과 ALB 생성까지 확인하엿으면 ../notion.txt 경로에 있는 주소를 통해 CloudFront,보안구성을 수동으로 생성합니다.

    (보안구성의 LB는 생략하여도 된다.)

 
06. 어떠한 장애가 발생하여 재 생성시 terraform destroy --auto-approve 를 사용하고,
   
    aws secretsmanager delete-secret --secret-id <SECRET_NAME> --force-delete-without-recovery
    
    ex) aws secretsmanager delete-secret --secret-id test-test-tset --force-delete-without-recovery

8. Bastion에 접근하여 ec2-user,root user 전부 다음 명령어를 통해 업데이트 해줍니다.

    aws eks update-kubeconfig --name <cluster_name> --region <region_code>

9. Test 채점 진행 후 5-1-A , 5-2-A 부분에서 데이터를 넣으니 database에 접근하여 해당 채점 항목에서 추가한 데이터를 삭제합니다.

    mysql security group으로 이동하여 Inbound 에 3310/bastion-sg 를 허용합니다.

    mysql -h <mysql_host> -u admin -P 3307 -p

    Skill53##

    use wsidata;

    delete from customer;

    delete from product;

10. Test 채점 진행 후 12-2으로 인해 CloudWatch LogGroup으로 이동하여 /wsi/webapp/<application_name> 의 Stream들을 전부 삭제합니다.
   
    이후, bastion에 ssh접근하여 다음 명령어들을 사용합니다.
    
    sudo su - ec2-user

    kubectl delete -f fluent-bit.yaml
    
    kubectl delete -f aws-logging-cloudwatch-configmap.yaml
    
    kubectl delete -f manifest/deployment.yaml
    
    kubectl delete -f  manifest/networkpolicy.yaml
    
    sleep 60
    
    kubectl apply -f fluent-bit.yaml
    
    kubectl apply -f aws-logging-cloudwatch-configmap.yaml
    
    kubectl apply -f manifest/deployment.yaml
    
    sleep 60
    
    kubectl apply -f  manifest/networkpolicy.yaml
    
    kubectl get pod -n wsi 명령어를 통하여 모든 Pod들이 Running 상태인지 확인해줍니다.

08. Test 채점 진행 후 13-3 부분에서 alb에 연결된 보안그룹에 인 바운드와 아웃 바운드에 80 port anyopen 부분을 제거해야 합니다.

    True : Inboud=80/pl-~~~ | Outbound=8080/node-sg 

    False : Inboud=80/pl-~~~,80/0.0.0.0/0 | Outbound=8080/node-sg,80/0.0.0.0/0 
