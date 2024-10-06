resource "aws_iam_role" "example_role" {
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

resource "aws_iam_role_policy_attachment" "example_attachment" {
    role       = aws_iam_role.example_role.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.example_role.name
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    key_name   = "gyeongbuk-key"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "gyeongbuk.pem"
    content  = tls_private_key.key.private_key_pem
}

data "aws_ami" "amazon_linux" {
  most_recent = true 
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

resource "aws_instance" "wsi-bastion-instance" {
    subnet_id = aws_subnet.public-subnet-a.id
    vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 
    instance_type = "t3.small"
    key_name = aws_key_pair.keypair.key_name          
    user_data = <<EOF
#!/bin/bash
yum install git -y
yum install docker -y 
sudo usermod -aG docker ec2-user
sudo systemctl enable --now docker
yum install nginx -y

cat << 'EOM' > /home/ec2-user/index.html
<!DOCTYPE HTML>
<html lang="ko">
	<head>
		<meta charset="UTF-8">
		<title>WSI v1</title>
	</head>
	
	<body>
		<h1>WSI v1</h1>
	</body>
</html>
EOM

cat << 'EOM' > /home/ec2-user/Dockerfile
FROM nginx:latest

COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOM

aws ecr create-repository --repository-name wsi-ecr --region ap-northeast-2
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t wsi-ecr /home/ec2-user
docker tag wsi-ecr:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-ecr:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-ecr:latest
EOF

    tags = {
        Name = "wsi-bastion"
    }
}