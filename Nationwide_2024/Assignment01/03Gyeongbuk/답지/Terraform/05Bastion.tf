resource "aws_iam_role" "wsi-role-bastion" {
    name = "wsi-role-bastion"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role_attachment" {
    role       = aws_iam_role.wsi-role-bastion.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "bastion_profile" {
    name = "bastion_profile"
    role = aws_iam_role.wsi-role-bastion.name
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    key_name = "gyeonbuk"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "wsi2024.pem"
    content = tls_private_key.key.private_key_pem
}

data "aws_ami" "amazon_linux" {
  most_recent = true 
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

resource "aws_instance" "wsi-bastion" {
    subnet_id = aws_subnet.public-subnet-a.id
    vpc_security_group_ids = [aws_security_group.bastion-security-groups.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
    instance_type = "t3.small"
    key_name = aws_key_pair.keypair.key_name
    user_data = <<EOF
#!/bin/bash
aws configure set default.region ${var.region}
cd /home/ec2-user
aws configure set default.region ${var.region}
### Port Change ###
sed -i 's/#Port 22/Port 4272/g' /etc/ssh/sshd_config
systemctl restart sshd

### DB install ###
sudo dnf update -y
sudo dnf install mariadb105 -y
sudo yum install jq -y

### Docker install ### 
sudo yum install docker -y
sudo systemctl enable docker

# Add the ec2-user to the Docker group
sudo usermod -aG docker ec2-user

# Restart Docker service to apply group changes
sudo systemctl restart docker

mkdir /home/ec2-user/customer
mkdir /home/ec2-user/order
mkdir /home/ec2-user/product
mkdir /home/ec2-user/manifest

# 파일들 s3에서 다운로드
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/cluster.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/deployment.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/svc.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/ingress.yaml /home/ec2-user/manifest/

aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/customer /home/ec2-user/customer
aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/order /home/ec2-user/order
aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/product /home/ec2-user/product

aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/fluent-bit.sh /home/ec2-user/fluent-bit.sh
aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/fluent-bit.yaml /home/ec2-user/fluent-bit.yaml

DB_PORT="3307"
DB_USER="admin"
DB_PASS="Skill53##" 
DB_NAME="wsidata"
RDS_ENDPOINT=${aws_rds_cluster.wsi_aurora_mysql_cluster.endpoint}
sleep 600
mysql -h $RDS_ENDPOINT -P $DB_PORT -u $DB_USER -p$DB_PASS <<SQL
USE $DB_NAME;

CREATE TABLE IF NOT EXISTS customer (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    gender VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS product (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    category VARCHAR(255)
);
SQL

cat << "CUS" > /home/ec2-user/customer/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY . /application
ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=Skill53##
ENV MYSQL_HOST=${aws_rds_cluster.wsi_aurora_mysql_cluster.endpoint}
ENV MYSQL_PORT=3307
ENV MYSQL_DBNAME=wsidata
ENV GIN_MODE=release 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./customer"]
CUS

cat << "PRO" > /home/ec2-user/product/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY . /application
ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=Skill53##
ENV MYSQL_HOST=${aws_rds_cluster.wsi_aurora_mysql_cluster.endpoint}
ENV MYSQL_PORT=3307
ENV MYSQL_DBNAME=wsidata
ENV GIN_MODE=release 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./product"]
PRO

cat << "ORD" > /home/ec2-user/order/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY . /application
ENV AWS_REGION=${var.region}
ENV GIN_MODE=release 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./order"]
ORD

aws ecr create-repository --repository-name customer-ecr --image-scanning-configuration scanOnPush=true
aws ecr create-repository --repository-name product-ecr --image-scanning-configuration scanOnPush=true
aws ecr create-repository --repository-name order-ecr --image-scanning-configuration scanOnPush=true

sudo su - ec2-user
cd /home/ec2-user/customer
chmod +x customer
aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
docker build -t customer-ecr .
docker tag customer-ecr:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/customer-ecr:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/customer-ecr:latest

cd /home/ec2-user/order
chmod +x order
aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
docker build -t order-ecr .
docker tag order-ecr:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/order-ecr:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/order-ecr:latest

cd /home/ec2-user/product
chmod +x product
aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
docker build -t product-ecr .
docker tag product-ecr:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/product-ecr:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/product-ecr:latest

# EKS Create
yum install curl --allowerasing -y
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/bin/
curl -O --silent --location https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/bin/
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
cd /home/ec2-user/
nohup eksctl create cluster -f manifest/cluster.yaml &
EKSCTL_PID=$!
wait $EKSCTL_PID

# App Fagate Profile Create
nohup eksctl create fargateprofile --cluster wsi-eks-cluster --name wsi-app-fargate-profile --namespace wsi --labels app=order --region ${var.region} &
PROFILE_PID=$!
wait $PROFILE_PID

# Service Account 
eksctl create iamserviceaccount --cluster=wsi-eks-cluster --name=admin-sa --attach-policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --namespace=wsi --region ${var.region} --approve

# Deployement
kubectl create ns wsi
kubectl apply -f manifest/deployment.yaml

# Subnet Tag Attach #
aws ec2 create-tags --resources ${aws_subnet.public-subnet-a.id}  ${aws_subnet.public-subnet-b.id} --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources ${aws_subnet.app-subnet-a.id} ${aws_subnet.app-subnet-b.id} --tags Key=kubernetes.io/role/internal-elb,Value=1

# Service
kubectl apply -f manifest/svc.yaml

#helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#OIDC 생성
eksctl utils associate-iam-oidc-provider --cluster wsi-eks-cluster --approve --region ${var.region}

#AWS Load Balancer Controller의 IAM 정책을 다운로드
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json

#다운로드 한 정책을 사용하여 IAM정책을 만듬
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

#생성한 정책을 사용하여 serviceaccount 생성
eksctl create iamserviceaccount \
  --cluster=wsi-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::073762821266:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region ${var.region}

#eks-charts 리포지토리를 추가
helm repo add eks https://aws.github.io/eks-charts

#로컬 리포지토리를 업데이트
helm repo update

#Load Balancer Controller을 설치
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wsi-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set nodeSelector.app=other

# 변수 설정
CLUSTER_NAME="wsi-eks-cluster"
ALB_SG_TAG_NAME="wsi-app-alb-sg"

# 노드 그룹 보안 그룹 ID 확인
NODEGROUP_SG_ID=$(aws eks describe-cluster --name wsi-eks-cluster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

# ALB 보안 그룹 ID 확인
ALB_SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=$ALB_SG_TAG_NAME --query 'SecurityGroups[*].GroupId' --output text)

# 보안 그룹 규칙 추가
aws ec2 authorize-security-group-ingress --group-id $NODEGROUP_SG_ID --protocol tcp --port 8080 --source-group $ALB_SG_ID

aws ec2 authorize-security-group-egress --group-id $ALB_SG_ID --protocol tcp --port 8080 --source-group $NODEGROUP_SG_ID

sleep 30
kubectl apply -f manifest/ingress.yaml

# Fargate Role 
FARGATE_ROLE=$(aws eks describe-fargate-profile --cluster-name wsi-eks-cluster --fargate-profile-name wsi-app-fargate-profile --query 'fargateProfile.podExecutionRoleArn' --output text | cut -d '/' -f 2)
aws iam attach-role-policy --role-name $FARGATE_ROLE --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

cd /home/ec2-user

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

chmod +x /home/ec2-user/fluent-bit.sh
/home/ec2-user/fluent-bit.sh

kubectl apply -f /home/ec2-user/fluent-bit.yaml

cd /home/ec2-user

cat << "NAM" > /home/ec2-user/aws-observability-namespace.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: aws-observability
  labels:
    aws-observability: enabled
NAM

kubectl apply -f /home/ec2-user/aws-observability-namespace.yaml

cat << "CFG" > /home/ec2-user/aws-logging-cloudwatch-configmap.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  flb_log_cw: "false"  # Set to true to ship Fluent Bit process logs to CloudWatch.
  filters.conf: |
    [FILTER]
        Name parser
        Match *
        Key_name log
        Parser crio
    [FILTER]
        Name kubernetes
        Match kube.*
        Merge_Log On
        Keep_Log Off
        Buffer_Size 0
        Kube_Meta_Cache_TTL 300s

    [FILTER]
        Name grep
        Match *
        Exclude log /healthcheck

  output.conf: |
    [OUTPUT]
        Name cloudwatch_logs
        Match kube.*
        region ${var.region}
        log_group_name /wsi/webapp/order
        log_stream_prefix from-fluent-bit-
        log_retention_days 60
  parsers.conf: |
    [PARSER]
        Name crio
        Format Regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
CFG

kubectl apply -f /home/ec2-user/aws-logging-cloudwatch-configmap.yaml
kubectl delete -f manifest/deployment.yaml
kubectl apply -f manifest/deployment.yaml

kubectl create namespace tigera-operator
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator --version v3.28.0 --namespace tigera-operator

cat << "NET" > /home/ec2-user/manifest/networkpolicy.yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
  namespace: wsi
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
    - Ingress
    - Egress

---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-external
  namespace: wsi
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 10.1.0.0/16
      ports:
        - protocol: TCP
          port: 8080

---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: block-product-to-customer
  namespace: wsi
spec:
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
NET

kubectl apply -f /home/ec2-user/manifest/networkpolicy.yaml
EOF
    tags = {
        Name = "wsi-bastion"
    }
}
