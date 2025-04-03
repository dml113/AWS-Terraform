data "aws_ami" "this" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP에서 HTTP 접근 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for nginx-server Host
resource "aws_iam_role" "nginx-server" {
  name = "nginx-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "nginx-server-role"
  }
}

# IAM Policy for nginx-server Host
resource "aws_iam_role_policy" "nginx-server" {
  name   = "${"nginx-server-role"}-policy"
  role   = aws_iam_role.nginx-server.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# Instance Profile for nginx-server Host
resource "aws_iam_instance_profile" "nginx-server" {
  name = "nginx-server-role"
  role = aws_iam_role.nginx-server.name
}

resource "aws_instance" "app-server-a" {
  ami = data.aws_ami.this.id

  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nginx-server.name
  vpc_security_group_ids      = [aws_security_group.web_server_sg.id]
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y nginx
echo "app-server-a Page" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx
EOF
  tags = {
    Name = "app-server-a"
  }
}

resource "aws_instance" "app-server-c" {
  ami = data.aws_ami.this.id

  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[1]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nginx-server.name
  vpc_security_group_ids      = [aws_security_group.web_server_sg.id]
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y nginx
echo "app-server-c Page" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx
EOF
  tags = {
    Name = "app-server-c"
  }
}