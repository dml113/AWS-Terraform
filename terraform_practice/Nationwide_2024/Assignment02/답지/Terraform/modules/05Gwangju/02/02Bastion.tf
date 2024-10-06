#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-keypair2.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "task12.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}


#
# Create Security_Group
#
  resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "warm-bastion-ec2-sg"
  description = "warm-bastion-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "warm-bastion-ec2-sg"
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
  name               = "warm-bastion-role2"
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
  name = "bastion_profiles_a2"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
  resource "aws_instance" "Bastion_Instance" {
  subnet_id     = aws_subnet.public_subnet_a.id
  security_groups = [aws_security_group.Bastion_Instance_SG.id]
  ami           = "ami-01123b84e2a4fba05" #amazonlinux2023
  iam_instance_profile   = aws_iam_instance_profile.bastion_profiles.name
  instance_type = "t3.small"
  key_name = "bastion-keypair2.pem"
  user_data = <<EOF
#!/bin/bash
sudo yum install git -y
sudo yum install docker -y
sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker ec2-user
sudo systemctl restart docker
mkdir /home/ec2-user/manifest
mkdir /home/ec2-user/application

aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/manifest/cluster.yaml /home/ec2-user/manifest/

aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/application/main.py /home/ec2-user/application/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/application/requirements.txt /home/ec2-user/application/
aws s3 cp s3://${aws_s3_bucket.my_bucket.id}/application/Dockerfile /home/ec2-user/application/

cd /home/ec2-user/application
chmod +x main.py
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t wsc2024-ecr .
docker tag wsc2024-ecr:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsc2024-ecr:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsc2024-ecr:latest

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
cd /home/ec2-user/
kubectl create ns app
cluster=warm-eks-clusterA
region=ap-northeast-2
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
aws ec2 create-tags --resources ${aws_subnet.public_subnet_a.id}  ${aws_subnet.public_subnet_b.id} --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources ${aws_subnet.private_subnet_a.id} ${aws_subnet.private_subnet_b.id} --tags Key=kubernetes.io/role/internal-elb,Value=1
EOF

  tags = {
    Name = "warm-bastion-ec2"
  }
}

#
# Create Bastion_EIP
#
  resource "aws_eip" "bastion_eip" {
  domain   = "vpc"

  tags = {
    Name = "warm-bastion-eip"
  }
 } 

resource "aws_eip_association" "bastion_eip_assocation" {
  instance_id   = aws_instance.Bastion_Instance.id
  allocation_id = aws_eip.bastion_eip.id
}