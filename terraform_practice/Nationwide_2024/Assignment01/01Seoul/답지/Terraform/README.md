# README.md

- marking1.sh 주의사항
01. 다음과 같은 순으로 Terraform apply 진행합니다. terraform init -> terraform apply --auto-approve
02. CloudFront 외 전부 자동화 입니다. (../notion.txt 경로에 잇는 주소를 확인합니다.)
03. Terraform apply 가 완료된 후에는 Console로 이동하여 CloudFormation 부분에 EKS가 생성되는 것까지 대기합니다.

    (1시간 30이내에 EKS까지가 정상입니다.)
  
04. EKS 생성과 ALB 생성까지 확인하엿으면 CloudFront Console로 이동하여 생성합니다. (../notion.txt 경로에 잇는 주소를 확인합니다.)

05. Bastion에 접근하여 ec2-user,root user 전부 다음 명령어를 통해 업데이트 해줍니다.

    aws eks update-kubeconfig --name <cluster_name> --region <region_code>

06. 어떠한 장애가 발생하여 재 생성시 terraform destroy --auto-approve 를 사용하고,

    kms.tf 이동 -> 49,55,92,98 줄 Name 수정


08. cloudwatch에 application log가 안 올라올 시 Bastion에 접근 후 다음 명령어를 사용합니다.

    /home/ec2-user/fluent-bit.sh 
    
    kubectl delete -f /home/ec2-user/fluent-bit.yaml
    kubectl apply -f /home/ec2-user/fluent-bit.yaml

09. 모든 인프라 구성이 끝이 나게 되면 rds sg inbound의 3310/bastion도 허용합니다. (절대 기존 rule 삭제하면 안 됩니다.)

10. Test 채점 진행 후 10-1-A , 10-2-A , 10-3-A 부분에서 데이터를 넣으니 database에 접근하여 해당 채점 항목에서 추가한 데이터를 삭제합니다.

    mysql security group으로 이동하여 Inbound 에 3310/bastion-sg 를 허용합니다.

    mysql -h <mysql_host> -u admin -P 3310 -p

    <비밀번호는 SecretManager에서 확인>

    use mydb;

    delete from customer;
    
    delete from product;

- marking2.sh 주의사항 

01. Test 채점 6-6-A 은 그냥 진행하면 됩니다.

02. Test 채점 10-4-A , 10-5-A 부분에서 ap-northest-2와 us-east-1 S3 Bucket index.html이 삭제됩니다.

    Test 채점이 종료된 후 다시 index.html을 업로드 해줍니다.
