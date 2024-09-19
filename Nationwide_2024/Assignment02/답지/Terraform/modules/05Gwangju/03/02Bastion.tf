#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-keypair3.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "task13.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}


#
# Create Security_Group
#
  resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "warm-bastion-ec2-sg"
  description = "bastion-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "bastion-ec2-sg"
  }
}

#
# Create Security_Group_Rule
#

  resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
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
  name               = "bastion-role3"
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
  name = "bastion-role3"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
  resource "aws_instance" "Bastion_Instance" {
  subnet_id     = aws_subnet.public_subnet_a.id
  security_groups = [aws_security_group.Bastion_Instance_SG.id]
  ami           = "ami-0edc5427d49d09d2a" #amazonlinux2023
  iam_instance_profile   = aws_iam_instance_profile.bastion_profiles.name
  instance_type = "t3.small"
  key_name = "bastion-keypair3.pem"
  user_data = <<EOF
#!/bin/bash
### docker install ###
yum install -y docker
usermod -a -G docker ec2-user
systemctl enable --now docker

### folder create ###
mkdir manifest

### S3 file pull ### 
aws s3 sync s3://${aws_s3_bucket.my_bucket.id} /home/ec2-user/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/cluster.yaml /home/ec2-user/manifest
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/deployment.yaml /home/ec2-user/manifest

aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/fluentd.yaml /home/ec2-user/manifest

### ECR Push ###
# Service A
cd /home/ec2-user/application/service-a
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t service-a .
docker tag service-a:latest ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:a
docker push ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:a

# Service B
cd /home/ec2-user/application/service-b
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t service-b .
docker tag service-b:latest ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:b
docker push ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:b

# Service C
cd /home/ec2-user/application/service-c
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t service-c .
docker tag service-c:latest ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:c
docker push ${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:c

### EKS Create ###
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

kubectl create ns fluentd
kubectl create ns app

ROLE_NAME=$(aws eks describe-nodegroup --cluster-name skills-eks-cluster --nodegroup-name warm-app-ngA --query "nodegroup.nodeRole" --output text | awk -F'/' '{print $2}')
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

sleep 10
kubectl apply -f manifest/deployment.yaml

sleep 10
kubectl apply -f manifest/fluentd.yaml

sleep 30
kubectl exec -it -n app deployment.apps/service-a -- curl localhost:8080 > /dev/null 2>&1
kubectl exec -it -n app deployment.apps/service-b -- curl localhost:8080 > /dev/null 2>&1
kubectl exec -it -n app deployment.apps/service-c -- curl localhost:8080 > /dev/null 2>&1
EOF

  tags = {
    Name = "bastion-ec2"
  }
}

#
# Create Bastion_EIP
#
  resource "aws_eip" "bastion_eip" {
  domain   = "vpc"

  tags = {
    Name = "bastion-eip"
  }
 } 

resource "aws_eip_association" "bastion_eip_assocation" {
  instance_id   = aws_instance.Bastion_Instance.id
  allocation_id = aws_eip.bastion_eip.id
}