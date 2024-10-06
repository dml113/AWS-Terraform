data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "webapp_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_instance" "webapp_instance" {
  ami                         = data.aws_ami.webapp_ami.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet1.id
  vpc_security_group_ids      = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = false

  user_data = <<EOF
#!/bin/bash
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skill53##' | passwd --stdin ec2-user
dnf install python3-pip -y
pip3 install boto3
pip3 install flask
dnf install lynx -y

mkdir /home/ec2-user/templates

sleep 10
aws s3 cp s3://${aws_s3_bucket.bucket.id}/app.py /home/ec2-user
aws s3 cp s3://${aws_s3_bucket.bucket.id}/index.html /home/ec2-user/templates/

cd /home/ec2-user
aws configure set region ap-northeast-2
nohup python3 app.py > /dev/null 2>&1 &
EOF

  iam_instance_profile = aws_iam_instance_profile.gm_bastion_instance_profile.name

  tags = {
    Name = "gm-bastion"
  }
}

resource "aws_iam_policy" "gm_bastion_policy" {
  name        = "01gm_bastion_policy"
  description = "IAM policy for DynamoDB and S3 access"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:PutItem",
          "s3:PutObject",
          "s3:GetObject"
        ],
        "Resource": [
          "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/gm-db",
          "arn:aws:s3:::gm-${random_integer.random_number.result}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject"
        ],
        "Resource": [
          "arn:aws:s3:::gm-${random_integer.random_number.result}",
          "arn:aws:s3:::gm-${random_integer.random_number.result}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "gm_bastion_role" {
  name = "01gm_bastion_role"

  assume_role_policy = jsonencode({
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
  })
}

resource "aws_iam_role_policy_attachment" "gm_bastion_policy_attachment" {
  role       = aws_iam_role.gm_bastion_role.name
  policy_arn = aws_iam_policy.gm_bastion_policy.arn
}

resource "aws_iam_instance_profile" "gm_bastion_instance_profile" {
  name = "01gm_bastion_role"
  role = aws_iam_role.gm_bastion_role.name
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "01gm-scripts_role"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name               = "01gm-scripts_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "bastion_policy" {
  name        = "01gm-scripts_policy"
  description = "Policy allowing admin access to Bastion host"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "*",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_policy_attachment" {
  policy_arn = aws_iam_policy.bastion_policy.arn
  role       = aws_iam_role.bastion_role.name
}

resource "aws_instance" "scripts_instance" {
  ami                         = data.aws_ami.webapp_ami.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet1.id
  vpc_security_group_ids      = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name
  depends_on = [ 
    aws_nat_gateway.nat_gateway1
]

  user_data = <<EOF
#!/bin/bash
sleep 60
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skill53##' | passwd --stdin ec2-user
NAT_GATEWAY_IDS=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=nat-gateway-a" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text)
for NAT_GATEWAY_ID in $NAT_GATEWAY_IDS; do
  echo "Deleting NAT Gateway: $NAT_GATEWAY_ID"
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID
done

EIP_ALLOCATION_IDS=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=nat-gateway-a" \
  --query 'NatGateways[*].NatGatewayAddresses[*].AllocationId' \
  --output text)
for EIP_ALLOCATION_ID in $EIP_ALLOCATION_IDS; do
  echo "Releasing EIP: $EIP_ALLOCATION_ID"
  aws ec2 release-address --allocation-id $EIP_ALLOCATION_ID
done
EOF

  tags = {
    Name = "gm-scripts"
  }
}

