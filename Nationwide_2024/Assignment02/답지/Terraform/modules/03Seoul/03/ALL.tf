provider "aws" {
  region = var.region
}

# VPC 생성
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# 서브넷 생성
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "main_subnet"
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# 보안 그룹 생성
resource "aws_security_group" "bastion_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "bastion_sg"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "BastionSecurityGroup"
  }
}

resource "aws_eip" "bastionEIP" {
  depends_on = [ aws_instance.bastion ]
  domain                    = "vpc"
  instance = aws_instance.bastion.id
}

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


resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pair" {
  key_name   = "seoul_wsi-pair.pem"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "file" {
  filename        = "seoul_wsi-pair.pem"
  content         = tls_private_key.key.private_key_pem
}

# EC2 Instance 생성
resource "aws_instance" "bastion" {
  ami           = "ami-0b8414ae0d8d8b4cc"  # 사용하려는 AMI ID로 변경
  instance_type = "t3.micro"
  key_name = aws_key_pair.pair.key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.main_subnet.id
  iam_instance_profile        = aws_iam_instance_profile.bastion_profiles.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y curl jq
              echo "Skill53" | passwd --stdin ec2-user
              sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
              systemctl restart sshd
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              EOF

  tags = {
    Name = "BastionInstance"
  }
}

# IAM 사용자 생성
resource "aws_iam_user" "tester" {
  name = "tester"
}

# AdministratorAccess 정책 부여
resource "aws_iam_user_policy_attachment" "tester_admin_policy" {
  user       = aws_iam_user.tester.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# MFA 활성화하지 않으면 S3 버킷을 삭제할 수 없는 정책 생성 및 부여
resource "aws_iam_policy" "mfa_bucket_delete_control" {
  name        = "mfaBucketDeleteControl"
  description = "Deny S3 bucket deletion if MFA is not enabled"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyBucketDeletionWithoutMFA",
            "Effect": "Deny",
            "Action": "s3:DeleteBucket",
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "tester_mfa_policy" {
  user       = aws_iam_user.tester.name
  policy_arn = aws_iam_policy.mfa_bucket_delete_control.arn
}

# 사용자 그룹 생성 및 사용자 추가
resource "aws_iam_group" "user_group_kr" {
  name = "user_group_kr"
}

resource "aws_iam_group_membership" "add_tester_to_group" {
  name = "tester-group-membership"
  users = [
    aws_iam_user.tester.name
  ]
  group = aws_iam_group.user_group_kr.name
}

# 리전 접근 제한 정책 생성 및 그룹에 적용
resource "aws_iam_policy" "region_access_control" {
  name        = "regionAccessControl"
  description = "Allow access to resources only in ap-northeast-2 region"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": "ap-northeast-2"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "attach_region_policy" {
  group      = aws_iam_group.user_group_kr.name
  policy_arn = aws_iam_policy.region_access_control.arn
}
