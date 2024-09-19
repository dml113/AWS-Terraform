#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-keypair.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "bastion_local" {
  filename        = "task1.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}

#
# Create Security_Group
#
resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "wsc2024-bastion-sg"
  vpc_id      = aws_vpc.wsc2024-ma-vpc.id

  tags = {
    Name = "wsc2024-bastion-sg"
  }
}

#
# Create Security_Group_Rule
#
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 28282
  to_port           = 28282
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

resource "aws_security_group_rule" "Bastion_Instance_SG_egress1" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

resource "aws_security_group_rule" "Bastion_Instance_SG_egress2" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

resource "aws_security_group_rule" "Bastion_Instance_SG_egress3" {
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

#
# Create Bastion_Role
#
data "aws_iam_policy_document" "AdministratorAccessDocument" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_role" {
name               = "wsc2024-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.AdministratorAccessDocument.json
}

resource "aws_iam_role_policy_attachment" "bastion_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}

#
# Create Bastion_profile
#
resource "aws_iam_instance_profile" "bastion_profiles" {
  name = "wsc2024-bastion-role"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
resource "aws_instance" "Bastion_Instance" {
  subnet_id                   = aws_subnet.wsc2024-ma-mgmt-sn-a.id
  security_groups             = [aws_security_group.Bastion_Instance_SG.id]
  ami                         = "ami-0bb84b8ffd87024d8" #amazonlinux2023
  iam_instance_profile        = aws_iam_instance_profile.bastion_profiles.name
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.bastion_keypair.key_name
  # account id 무조건 변경
  # bucket name도 변경
  user_data                   = <<-EOF
#!/bin/bash
# port 변경
sed -i 's/#Port 22/Port 28282/g' /etc/ssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd

# mysql 설치
sudo dnf update -y
sudo dnf install mariadb105 -y
sudo yum install jq -y

# docker 설치
sudo yum install docker -y
sudo systemctl enable docker
sudo systemctl restart docker

# Add the ec2-user to the Docker group
sudo usermod -aG docker ec2-user

# Restart Docker service to apply group changes
sudo systemctl restart docker

# Download the order file from S3
mkdir /home/ec2-user/customer
mkdir /home/ec2-user/order
mkdir /home/ec2-user/product
mkdir /home/ec2-user/manifest

# 파일들 s3에서 다운로드
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/gw.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/hr.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/tgp.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/cluster.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/cluster.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/deployment.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/svc.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/ingress.yaml /home/ec2-user/manifest/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/app/customer /home/ec2-user/customer
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/app/order /home/ec2-user/order
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/app/product /home/ec2-user/product

# Define database connection variables
DB_PORT="3306"
DB_USER="admin"
DB_PASS="Skill53##" 
DB_NAME="wsc2024_db"
RDS_ENDPOINT=${aws_rds_cluster.aurora_cluster.endpoint}
sleep 960
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

# Create Dockerfile in the home directory
cat << "CUS" > /home/ec2-user/customer/Dockerfile
FROM golang:alpine

RUN apk add libc6-compat

WORKDIR /application/

COPY . /application

ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=Skill53##
ENV MYSQL_HOST=${aws_rds_cluster.aurora_cluster.endpoint}
ENV MYSQL_PORT=3306
ENV MYSQL_DBNAME=wsc2024_db

RUN cd /application/

EXPOSE 8080

CMD ["./customer"]
CUS

cat << "PRO" > /home/ec2-user/product/Dockerfile
FROM golang:alpine

RUN apk add libc6-compat

WORKDIR /application/

COPY . /application

ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=Skill53##
ENV MYSQL_HOST=${aws_rds_cluster.aurora_cluster.endpoint}
ENV MYSQL_PORT=3306
ENV MYSQL_DBNAME=wsc2024_db

RUN cd /application/

EXPOSE 8080

CMD ["./product"]
PRO

cat << "ORD" > /home/ec2-user/order/Dockerfile
FROM golang:alpine

RUN apk add libc6-compat

WORKDIR /application/

COPY . /application

ENV AWS_REGION=us-east-1

RUN cd /application/

EXPOSE 8080

CMD ["./order"]
ORD

# Images Upload
sudo su - ec2-user
cd /home/ec2-user/customer
chmod +x customer
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
docker build -t customer-repo .
docker tag customer-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/customer-repo:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/customer-repo:latest

cd /home/ec2-user/order
chmod +x order
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
docker build -t order-repo .
docker tag order-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/order-repo:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/order-repo:latest

cd /home/ec2-user/product
chmod +x product
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
docker build -t product-repo .
docker tag product-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/product-repo:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/product-repo:latest

# EKS 생성
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
sudo chmod 777 /home/ec2-user/.kube/config
kubectl create ns wsc2024
kubectl apply -f manifest/deployment.yaml
kubectl apply -f manifest/svc.yaml
cluster=wsc2024-eks-cluster
region=us-east-1
account=${data.aws_caller_identity.current.account_id}
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
eksctl create iamserviceaccount \
  --cluster=$cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$account:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=$region
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

aws ec2 create-tags --resources ${aws_subnet.wsc2024-prod-load-sn-a.id}  ${aws_subnet.wsc2024-prod-load-sn-b.id} --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources ${aws_subnet.wsc2024-prod-app-sn-a.id} ${aws_subnet.wsc2024-prod-app-sn-b.id} --tags Key=kubernetes.io/role/internal-elb,Value=1
sleep 30
kubectl apply -f manifest/ingress.yaml

ROLE_NAME=$(aws eks describe-nodegroup --cluster-name wsc2024-eks-cluster --nodegroup-name wsc2024-db-application-ng --query "nodegroup.nodeRole" --output text | awk -F'/' '{print $2}')
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

INSTANCE_PROFILE_ARNS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsc2024-db-application-node" --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text)
IFS=' ' read -r -a INSTANCE_PROFILE_ARRAY <<< "$INSTANCE_PROFILE_ARNS"
for INSTANCE_PROFILE_ARN in "$INSTANCE_PROFILE_ARRAY[@]"; do
  ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $(basename $INSTANCE_PROFILE_ARN) --query "InstanceProfile.Roles[*].RoleName" --output text)
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
done

export AWS_REGION=us-east-1
export CLUSTER_NAME=wsc2024-eks-cluster
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=$PREFIX_LIST_ID}],IpProtocol=-1"
PREFIX_LIST_ID_IPV6=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=$PREFIX_LIST_ID_IPV6}],IpProtocol=-1"
curl https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/recommended-inline-policy.json  -o recommended-inline-policy.json
aws iam create-policy \
    --policy-name VPCLatticeControllerIAMPolicy \
    --policy-document file://recommended-inline-policy.json
export VPCLatticeControllerIAMPolicyArn=$(aws iam list-policies --query 'Policies[?PolicyName==`VPCLatticeControllerIAMPolicy`].Arn' --output text)
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/deploy-namesystem.yaml
aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent --addon-version v1.0.0-eksbuild.1
cat >gateway-api-controller-service-account.yaml << GAT
apiVersion: v1
kind: ServiceAccount
metadata:
    name: gateway-api-controller
    namespace: aws-application-networking-system
GAT

kubectl apply -f gateway-api-controller-service-account.yaml
cat >trust-relationship.json <<GAC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
GAC
aws iam create-role --role-name VPCLatticeControllerIAMRole --assume-role-policy-document file://trust-relationship.json --description "IAM Role for AWS Gateway API Controller for VPC Lattice"
aws iam attach-role-policy --role-name VPCLatticeControllerIAMRole --policy-arn=$VPCLatticeControllerIAMPolicyArn
export VPCLatticeControllerIAMRoleArn=$(aws iam list-roles --query 'Roles[?RoleName==`VPCLatticeControllerIAMRole`].Arn' --output text)
aws eks create-pod-identity-association --cluster-name $CLUSTER_NAME --role-arn $VPCLatticeControllerIAMRoleArn --namespace aws-application-networking-system --service-account gateway-api-controller
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/deploy-v1.0.5.yaml
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/gatewayclass.yaml
export AWS_REGION=us-east-1
export CLUSTER_NAME=wsc2024-eks-cluster
aws vpc-lattice create-service-network --name wsc2024-lattice-svc-net
SERVICE_NETWORK_ID=$(aws vpc-lattice list-service-networks --query "items[?name=="\'wsc2024-lattice-svc-net\'"].id" | jq -r '.[]')
CLUSTER_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wsc2024-ma-vpc" --query "Vpcs[0].VpcId" --output text)
aws vpc-lattice create-service-network-vpc-association --service-network-identifier $SERVICE_NETWORK_ID --vpc-identifier $CLUSTER_VPC_ID
kubectl apply -f manifest/gw.yaml
kubectl apply -f manifest/hr.yaml
kubectl apply -f manifest/tgp.yaml

aws elbv2 describe-load-balancers --names wsc2024-alb --query 'LoadBalancers[0].DNSName' --output text > /home/ec2-user/ingress-address.txt
aws s3 cp /home/ec2-user/ingress-address.txt s3://${aws_s3_bucket.my_bucket.id}/ingress-address.txt
EOF

  tags = {
    Name = "wsc2024-bastion-ec2"
  }
}

#
# Create Bastion_EIP
#
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = "wsc2024-bastion-eip"
  }
}

resource "aws_eip_association" "bastion_eip_assocation" {
  instance_id   = aws_instance.Bastion_Instance.id
  allocation_id = aws_eip.bastion_eip.id
}