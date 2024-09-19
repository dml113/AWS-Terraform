# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wsc2024" {
  key_name   = "01wsc2024.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "01wsc2024.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}

# IAM 역할 생성
resource "aws_iam_role" "ec2_role" {
  name = "01wsc2024-role-bastion"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# AdministratorAccess 정책 연결
resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 보안 그룹 생성
resource "aws_security_group" "allow_all" {
vpc_id        = aws_default_vpc.default_vpc.id
  name        = "allow_all_traffic"
  description = "Allow all inbound and outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "my_instance" {
  ami = "ami-0ca1f30768d0cf0e1" # Amazon Linux 2023 AMI ID, 실제 AMI ID로 변경 필요
  subnet_id     = aws_default_subnet.default_vpc_subnet_a.id
  instance_type   = "t2.micro"
  key_name        = "01wsc2024.pem"
  security_groups = [aws_security_group.allow_all.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install git -y
              yum install docker -y
              systemctl enable --now docker
              usermod -aG docker ec2-user 
              
              # main.py 파일 생성
              cat << 'EOM' > /home/ec2-user/main.py
              from flask import Flask, request, render_template
              import time
              import socket
              import sys
              from datetime import datetime, timedelta

              app = Flask(__name__)

              @app.route('/')
              def index():
                  return render_template('index.html')

              @app.route('/healthcheck')
              def health():
                  return '{"status": "200 OK"}'

              @app.route('/request')
              def request_info():
                  want = request.args.get('want', '')

                  if want == 'time':
                      current_time = datetime.now()
                      current_time -= timedelta(hours=3)
                      current_time_str = current_time.strftime("%Y-%m-%d %H:%M:%S")
                      return f"Current time is: {current_time_str}"

                  elif want == 'myip':
                      ip_address = socket.gethostbyname(socket.gethostname())
                      return f"My IP address is: {ip_address}"

                  else:
                      return "Invalid request. Please provide 'want=time' or 'want=myip' in the query string."

              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=8080)
              EOM

              # requirements.txt 파일 생성
              cat << 'EOM' > /home/ec2-user/requirements.txt
              Flask==3.0.2
              EOM

              # index.html 파일 생성
              mkdir -p /home/ec2-user/templates
              cat << 'EOM' > /home/ec2-user/templates/index.html
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Chungcheongnam-do Page</title>
                  <style>
                      body {
                          font-family: 'Nanum Gothic', sans-serif;
                          margin: 0;
                          padding: 0;
                          height: 100vh;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                          overflow: hidden;
                          position: relative;
                          background: url('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQdrLFh_BIJzPiET-3kJgjcBV3tUJ_h7DvGsyvVZQirWw&s') no-repeat center center/cover;
                      }

                      .overlay {
                          position: absolute;
                          top: 0;
                          left: 0;
                          width: 100%;
                          height: 100%;
                          background-color: rgba(255, 255, 255, 0.6);
                          backdrop-filter: blur(10px);
                      }

                      .content {
                          position: relative;
                          text-align: center;
                          z-index: 1;
                          background-color: rgba(255, 255, 255, 0.8);
                          padding: 20px;
                          border-radius: 10px;
                          box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                      }

                      h1 {
                          font-size: 3em;
                          color: #333;
                          margin-bottom: 20px;
                      }

                      p {
                          font-size: 1.2em;
                          color: #666;
                      }
                  </style>
              </head>
              <body>
                  <div class="overlay"></div>
                  <div class="content">
                      <h1>Chungcheongnam-do Page</h1>
                      <p>This page was developed in Gongju Meister High School, South Chungcheong Province.</p>
                  </div>
              </body>
              </html>
              EOM

              # main.py 파일 생성
              cat << 'EOM' > /home/ec2-user/Dockerfile
              FROM python:3.12-alpine
              WORKDIR /app
              COPY . .
              RUN pip install -r requirements.txt
              RUN apk update
              RUN apk add curl  
              CMD ["python3", "main.py"]
              EOM

              aws ecr create-repository --repository-name wsc2024-repo --region us-west-1

              aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-1.amazonaws.com
              docker build -t wsc2024-repo /home/ec2-user
              docker tag wsc2024-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-1.amazonaws.com/wsc2024-repo:latest
              docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-1.amazonaws.com/wsc2024-repo:latest
EOF

  tags = {
    Name = "wsc2024-bastion"
  }
}

# IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "01ec2-instance-profile" 
  role = aws_iam_role.ec2_role.name
}