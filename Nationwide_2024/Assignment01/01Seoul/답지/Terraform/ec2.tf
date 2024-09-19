resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    provider = aws.ap
    key_name = "seoul"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "seoul.pem"
    content = tls_private_key.key.private_key_pem
}

resource "aws_security_group" "wsi_bastion_sg" {
  provider = aws.ap
  name        = "wsi-bastion-sg"
  description = "Security group for Bastion server allowing SSH access only"
  vpc_id      = aws_vpc.wsi_vpc.id

  ingress {
    from_port   = 4272
    to_port     = 4272
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "wsi_bastion_role" {
  name = "wsi-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "wsi_bastion_role_policy_attachment" {
  role       = aws_iam_role.wsi_bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_instance" "wsi_bastion" {
  provider = aws.ap
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.wsi_public_a.id
  key_name               = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.wsi_bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.wsi_bastion_profile.name

  tags = {
    Name = "wsi-bastion"
  }

  user_data = <<-EOF
#!/bin/bash
sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skill53##' | passwd --stdin ec2-user
aws configure set default.region ap-northeast-2
dnf update -y
dnf install -y aws-cli jq curl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/bin/
eksctl version
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
sed -i 's/#Port 22/Port 4272/g' /etc/ssh/sshd_config
systemctl restart sshd

dnf install mariadb105 -y
dnf install docker -y 
usermod -aG docker ec2-user
systemctl enable --now docker 

mkdir -p /home/ec2-user/app/customer
mkdir -p /home/ec2-user/app/product
mkdir -p /home/ec2-user/app/order

cd /home/ec2-user
mkdir -p k8s/cluster
mkdir -p k8s/manifest


aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/cluster.yaml /home/ec2-user/k8s/cluster
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/ss.yaml /home/ec2-user/k8s/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/deployment.yaml /home/ec2-user/k8s/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/svc.yaml /home/ec2-user/k8s/manifest/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/manifest/ingress.yaml /home/ec2-user/k8s/manifest/

aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/customer /home/ec2-user/app/customer
aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/order /home/ec2-user/app/order
aws s3 cp s3://${aws_s3_bucket.bucket.id}/app/product /home/ec2-user/app/product
aws s3 cp s3://${aws_s3_bucket.bucket.id}/static/css/bootstrap.min.css /home/ec2-user/css/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/static/js/main.js /home/ec2-user/js/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/static/index.html /home/ec2-user/index.html
aws s3 cp s3://${aws_s3_bucket.bucket.id}/error/50x.html /home/ec2-user/error/50x.html

sleep 3
aws s3 cp /home/ec2-user/css/bootstrap.min.css s3://${aws_s3_bucket.ap_wsi_static.id}/css/bootstrap.min.css
aws s3 cp /home/ec2-user/js/main.js s3://${aws_s3_bucket.ap_wsi_static.id}/js/main.js
aws s3 cp /home/ec2-user/index.html s3://${aws_s3_bucket.ap_wsi_static.id}
aws s3 cp /home/ec2-user/error/50x.html s3://${aws_s3_bucket.ap_wsi_static.id}/error/50x.html

aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/fluent-bit.sh /home/ec2-user/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/fluent-bit.yaml /home/ec2-user/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/cwagent-fluentd-quickstart-enhanced.yaml /home/ec2-user/
aws s3 cp s3://${aws_s3_bucket.bucket.id}/logging/aws-logging-cloudwatch-configmap.yaml /home/ec2-user/

DB_PORT="3310"
DB_USER="admin"
DB_PASS=$(aws secretsmanager get-secret-value --secret-id $(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `rds!`)].Name' --output text) --query "SecretString" --output text | jq -r .password)
DB_NAME="mydb"
DB_ENDPOINT=${aws_db_instance.default.address}
mysql -h $DB_ENDPOINT -P $DB_PORT -u $DB_USER -p$DB_PASS <<SQL
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

cat << 'CUS' > /home/ec2-user/app/customer/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY customer Dockerfile /application
ENV MYSQL_HOST=${aws_db_instance.default.address}
ENV MYSQL_PORT=3310
ENV MYSQL_DBNAME=mydb 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./customer"]
CUS

cat << 'PRO' > /home/ec2-user/app/product/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY product Dockerfile /application
ENV MYSQL_HOST=${aws_db_instance.default.address}
ENV MYSQL_PORT=3310
ENV MYSQL_DBNAME=mydb 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./product"]
PRO

cat << "ORD" > /home/ec2-user/app/order/Dockerfile
FROM golang:alpine
RUN apk update && apk upgrade && \
    apk add --no-cache libc6-compat busybox
WORKDIR /application/
COPY . /application
ENV AWS_REGION=ap-northeast-2
ENV GIN_MODE=release 
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["./order"]
ORD

sudo su - ec2-user
cd /home/ec2-user/app/customer
chmod +x customer
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t customer .
docker tag customer:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/customer:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/customer:latest

cd /home/ec2-user/app/order
chmod +x order
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t order .
docker tag order:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/order:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/order:latest

cd /home/ec2-user/app/product
chmod +x product
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t product .
docker tag product:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/product:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/product:latest

cd /home/ec2-user/k8s
nohup eksctl create cluster -f cluster/cluster.yaml &
EKSCTL_PID=$!
wait $EKSCTL_PID

nohup eksctl create fargateprofile --cluster wsi-eks-cluster --name wsi-app-fargate --namespace wsi --labels app=order --region ap-northeast-2 &
PROFILE_PID=$!
wait $PROFILE_PID

aws eks update-kubeconfig --name wsi-eks-cluster

eksctl create iamserviceaccount --cluster=wsi-eks-cluster --name=admin-sa --attach-policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --namespace=wsi --region ap-northeast-2 --approve
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm install reloader stakater/reloader

helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
  external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --set nodeSelector.role=addon

eksctl create iamserviceaccount \
    --name aws-external-secret-manager  \
    --namespace wsi \
    --cluster wsi-eks-cluster \
    --role-name "ex-sm-role-ap" \
    --attach-policy-arn arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ex-sm-ap-policy \
    --approve \
    --override-existing-serviceaccounts   

RDS_SECRETS=$(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `rds!`)].Name' --output text)

cat << SEC > /home/ec2-user/k8s/manifest/es.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: aws-secrets
  namespace: wsi
spec:
  refreshInterval: 10s
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: secrets-manager-secret
    creationPolicy: Owner
  data:
  - secretKey: MYSQL_USER
    remoteRef:
      key: $RDS_SECRETS
      property: username
  - secretKey: MYSQL_PASSWORD
    remoteRef:
      key: $RDS_SECRETS
      property: password
SEC

kubectl apply -f /home/ec2-user/k8s/manifest/ss.yaml
kubectl apply -f /home/ec2-user/k8s/manifest/es.yaml
kubectl apply -f /home/ec2-user/k8s/manifest/deployment.yaml

aws ec2 create-tags --resources ${aws_subnet.wsi_public_a.id}  ${aws_subnet.wsi_public_b.id} --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources ${aws_subnet.wsi_app_a.id} ${aws_subnet.wsi_app_b.id} --tags Key=kubernetes.io/role/internal-elb,Value=1

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=wsi-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region ap-northeast-2

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wsi-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set nodeSelector.role=addon

sleep 30
kubectl apply -f /home/ec2-user/k8s/manifest/svc.yaml
kubectl apply -f /home/ec2-user/k8s/manifest/ingress.yaml

kubectl apply -f /home/ec2-user/cwagent-fluentd-quickstart-enhanced.yaml
sleep 5
# Fargate Role 
FARGATE_ROLE=$(aws eks describe-fargate-profile --cluster-name wsi-eks-cluster --fargate-profile-name wsi-app-fargate --query 'fargateProfile.podExecutionRoleArn' --output text | cut -d '/' -f 2)
aws iam attach-role-policy --role-name $FARGATE_ROLE --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

cat << "CLU" > /home/ec2-user/cloudwatch.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: amazon-cloudwatch
  labels:
    name: amazon-cloudwatch
CLU

kubectl apply -f /home/ec2-user/cloudwatch.yaml

chmod +x /home/ec2-user/fluent-bit.sh
/home/ec2-user/fluent-bit.sh

cluster=wsi-eks-cluster
policy=arn:aws:iam::aws:policy/AdministratorAccess
eksctl create iamserviceaccount --cluster $cluster --attach-policy-arn $policy --namespace amazon-cloudwatch --name fluent-bit --region ap-northeast-2 --approve

kubectl apply -f /home/ec2-user/fluent-bit.yaml
cat << "NAM" > /home/ec2-user/aws-observability-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: aws-observability
  labels:
    aws-observability: enabled
NAM

kubectl apply -f /home/ec2-user/aws-observability-namespace.yaml
kubectl apply -f /home/ec2-user/aws-logging-cloudwatch-configmap.yaml
kubectl delete -f /home/ec2-user/k8s/manifest/deployment.yaml
kubectl apply -f /home/ec2-user/k8s/manifest/deployment.yaml
sleep 60

aws eks update-cluster-config \
    --region ap-northeast-2 \
    --name wsi-eks-cluster \
    --resources-vpc-config endpointPrivateAccess=true,endpointPublicAccess=false

EKS_CONTROL=$(aws eks describe-cluster --name wsi-eks-cluster --query "cluster.resourcesVpcConfig.securityGroupIds[0]" --output text)
aws ec2 authorize-security-group-ingress --group-id $EKS_CONTROL --protocol tcp --port 443 --cidr 0.0.0.0/0

RDS_SG_ID=$(aws rds describe-db-instances --db-instance-identifier wsi-rds-mysql --query "DBInstances[0].VpcSecurityGroups[].VpcSecurityGroupId" --output text)
aws ec2 revoke-security-group-ingress --group-id $RDS_SG_ID --protocol tcp --port 3310 --cidr 0.0.0.0/0
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-app-node" --query "Reservations[*].Instances[*].InstanceId" --output text)
IDS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" --output text | tr '\t' '\n' | sort | uniq)
aws ec2 authorize-security-group-ingress --group-id $RDS_SG_ID --protocol tcp --port 3310 --source-group $IDS

aws s3 rm s3://${aws_s3_bucket.bucket.id} --recursive
aws s3api delete-bucket --bucket ${aws_s3_bucket.bucket.id}
EOF
}

data "aws_ami" "amazon_linux" {
  provider = aws.ap
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

resource "aws_iam_instance_profile" "wsi_bastion_profile" {
  name = "wsi-bastion-role"
  role = aws_iam_role.wsi_bastion_role.name
}