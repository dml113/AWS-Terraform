# README.md

1. 과제 분배가 완료되면 각 시도별 폴더에 Architecture.png 파일을 참고하여 main.tf 파일의 주석을 해제 하도록 합니다.
2. Terraform은 같은 순으로 진행 합니다.
    terraform init -> terraform apply --auto-approve (특정 시도는 apply 두 번 진행해야 합니다.)
3. files,modules 폴더는 수정or확인 작업이 필요하지 않습니다. 단, Reference는 꼭! 꼭! 확인하도록 합니다.
4. EKS가 포함된 시도일 경우 Terraform apply가 완료 되어도 20분 정도의 CloudFormation 동작 시간이 필요합니다.

   -> 광주2-2,광주2-3,대전2-3
5. Config관련 Error가 발생할 경우 Terraform apply를 한 번 더 진행하도록합니다.

    단, 이때 EKS가 포함된 apply를 진행하였다면 EKS 생성이 완료된 후 진행하도록 합니다.

6. 만약 AMI 관련 Error 가 발생할 경우 본인의 AMI로 직접 수정하여야 합니다.

----------------------------
01. 충남
   
충남 2-1: bastion-ec2 
충남 2-2: wsc2024-bastion
충남 2-3: gm-bastion, gm-scripts

충남 2-1
01task1.pem
충남 2-2
01wsc2024.pem
충남 2-3 
password: Skill53##

----------------------------
02. 제주

제주 2-1: serverless-bastion
제주 2-2: cg-bastion
제주 2-3: J-company-bastion

제주 2-1
Jeju_bastion.pem
제주 2-2
bastion2.pem
제주 2-3
endpoint 접근

----------------------------
03. 서울

서울 2-1: wsi-bastion
서울 2-2: wsi-test
서울 2-3: BastionInstance

서울 2-1
Seoul_bastion.pem
서울 2-2
wsi-pair.pem
서울 2-3
seoul_wsi-pair.pem

----------------------------
04. 경북

경북 2-1: wsi-bastion
경북 2-2: wsi-bastion
경북 2-3: wsi-bastion

경북 2-1
gyeongbuk.pem
경북 2-2
gyeongbuk2.pem
경북 2-3
gyeongbuk3.pem

----------------------------
05. 광주

광주 2-1: gwangju-EgressVPC-Instance, gwangju-VPC1-Instance, gwangju-VPC2-Instance
광주 2-2: warm-bastion-ec2
광주 2-3: bastion-ec2

광주 2-1
ssm 접근
광주 2-2
task12.pem
광주 2-3
task13.pem

----------------------------
05. 대전

대전 2-1: 없음. (shell)
대전 2-2: wsi-app-ec2
대전 2-3: wsi-bastion-ec2

대전 2-1
CloudShell 접근
대전 2-2
wsi-app-pair.pem
대전 2-3
wsi-app-pair2.pem

----------------------------
05. 부산

부산 2-1: wsi-project-ec2
부산 2-2: wsi-bastion-ec2
부산 2-3: wsi-bastion

부산 2-1
password: Skills2024**
부산 2-2
password: Skills2024**
부산 2-3
wsc2024.pem
