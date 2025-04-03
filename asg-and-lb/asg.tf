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

# Attach AdministratorAccess Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "nginx_server_admin_access" {
  role       = aws_iam_role.nginx-server.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance Profile for nginx-server Host
resource "aws_iam_instance_profile" "nginx-server" {
  name = "nginx-server-role"
  role = aws_iam_role.nginx-server.name
}

resource "aws_launch_template" "my_launch_template" {
  name = "nginx-lt"
  description = "My Launch Template"
  image_id = data.aws_ami.this.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y nginx
echo "$hostname Page" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx
EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "nginx-server"
    }
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name = "nginx-asg"
  desired_capacity   = 2
  max_size           = 10
  min_size           = 2
  vpc_zone_identifier  = module.vpc.private_subnets
  target_group_arns = [aws_lb_target_group.iac_nginx_alb.arn]
  health_check_type = "EC2"
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = aws_launch_template.my_launch_template.latest_version
  } 
}