data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID
}

resource "aws_security_group" "webapp_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 2220
    to_port = 2220
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  tags = {
    "Name" = "bastion-sg"
  }
}

resource "aws_instance" "webapp_instance" {
  ami = data.aws_ami.webapp_ami.id
  subnet_id = aws_subnet.public_subnet1.id
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  iam_instance_profile         = aws_iam_instance_profile.webapp_instance_profile.name
  user_data = <<EOF
#!/bin/bash
sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skills2024**' | passwd --stdin ec2-user
sudo sed -i 's/#Port 22/Port 2220/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo yum install jq -y
sudo yum install curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
EOF
  tags = {
    "Name" = "wsi-bastion-ec2"
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "wsi-bastion-ec2-role2"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

# AdministratorAccess 정책 연결
resource "aws_iam_role_policy_attachment" "bastion_role_admin_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "wsi-bastion-ec2-profile2"
  role = aws_iam_role.bastion_role.name
}