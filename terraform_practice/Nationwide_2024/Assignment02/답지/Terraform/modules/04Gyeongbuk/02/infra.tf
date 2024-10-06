resource "aws_vpc" "vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = "wsi-vpc"
    }
}

resource "aws_subnet" "public-subnet-a" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.0.0/24"
    availability_zone       = "${var.region}a"
    
    map_public_ip_on_launch = true    

    tags = {
        Name = "wsi-public-subnet-a"
    }
}

resource "aws_subnet" "public-subnet-b" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.region}b"

    map_public_ip_on_launch = true

    tags = {
        Name = "wsi-public-subnet-b"
    }
}

resource "aws_subnet" "private-subnet-a" {
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "${var.region}a"

    tags = {
        Name = "wsi-private-subnet-a"
    }
}

resource "aws_subnet" "private-subnet-b" {
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "${var.region}b"

    tags = {
        Name = "wsi-private-subnet-b"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
        Name = "wsi-igw"
    }
} 

resource "aws_eip" "nat-eip1" {
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_eip" "nat-eip2" {
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_nat_gateway" "ngw1" {
    allocation_id = aws_eip.nat-eip1.id
    subnet_id     = aws_subnet.public-subnet-a.id

    tags = {
        Name = "wsi-natgw-a"
    }
}

resource "aws_nat_gateway" "ngw2" {
    allocation_id = aws_eip.nat-eip2.id 
    subnet_id     = aws_subnet.public-subnet-b.id

    tags = {
        Name = "wsi-natgw-b"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-public-rtb"
    }
}

resource "aws_route_table" "private-a-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-private-rtb-a"
    }
}

resource "aws_route_table" "private-b-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-private-rtb-b"
    }
}

resource "aws_route" "public-route" {
    route_table_id         = aws_route_table.public-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private-a-route" {
    route_table_id         = aws_route_table.private-a-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_nat_gateway.ngw1.id
}

resource "aws_route" "private-b-route" {
    route_table_id         = aws_route_table.private-b-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_nat_gateway.ngw2.id
}

resource "aws_route_table_association" "private-route-table-association1" {
    route_table_id = aws_route_table.private-a-route-table.id
    subnet_id = aws_subnet.private-subnet-a.id 
}

resource "aws_route_table_association" "private-route-table-association2" {
    route_table_id = aws_route_table.private-b-route-table.id
    subnet_id = aws_subnet.private-subnet-b.id
}

resource "aws_route_table_association" "public-route-table-association1" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet-a.id
}

resource "aws_route_table_association" "public-route-table-association2" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet-b.id
}

# AWS EIP 정의
resource "aws_eip" "wsi-eip-bastion" {
  instance = aws_instance.wsi-bastion-instance.id
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "wsi-eip-bastion2"
  }
}

# IAM Role 정의
resource "aws_iam_role" "example_role" {
  name = "wsi-role-bastion2"
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

# IAM Role Policy Attachment 정의
resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Instance Profile 정의
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "04ec2_instance_profile2"
  role = aws_iam_role.example_role.name
}

# TLS Private Key 생성
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS Key Pair 생성
resource "aws_key_pair" "keypair" {
  key_name   = "gyeongbuk-key2"
  public_key = tls_private_key.key.public_key_openssh
}

# Local File 생성
resource "local_file" "downloads_key" {
  filename = "gyeongbuk2.pem"
  content  = tls_private_key.key.private_key_pem
}

# Bastion Security Group 생성
resource "aws_security_group" "wsi-bastion" {
  name        = "wsi-sg-bastion"
  description = "for wsi-bastion ec2"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "wsi-sg-bastion"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true 
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

# Bastion Instance 생성
resource "aws_instance" "wsi-bastion-instance" {
  subnet_id              = aws_subnet.public-subnet-a.id
  vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
  ami                    = "ami-0450ec15bbf42649e"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  instance_type          = "t3.small"
  key_name               = aws_key_pair.keypair.key_name
  tags = {
    Name = "wsi-bastion"
  }
}

# Private Instance A 생성
resource "aws_instance" "wsi-bastion-private-a-instance" {
  subnet_id              = aws_subnet.private-subnet-a.id
  vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.keypair.key_name
  user_data = <<EOF
#!/bin/bash
yum install python3-pip -y 
yum install nginx -y 
yum install docker -y
systemctl enable --now nginx 
usermod -aG docker ec2-user
systemctl enable --now docker 
cat << 'EOM' > /home/ec2-user/main.py
from flask import Flask, request, jsonify, make_response
import jwt
import datetime
import base64
import json

app = Flask(__name__)

SECRET_KEY = 'jwtsecret'

@app.route('/v1/token', methods=['GET'])
def get_token():
    payload = {
        'isAdmin': False,
        'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return jsonify({'token': token})

@app.route('/v1/token/verify', methods=['GET'])
def verify_token():
    token = request.headers.get('Authorization')
    if not token:
        return make_response('Token is missing', 403)

    decoded = jwt.decode(token, options={"verify_signature": False})
    isAdmin = decoded.get('isAdmin', False)
    if isAdmin:
        return 'You are admin!'
    else:
        return 'You are not permitted'

@app.route('/v1/token/none', methods=['GET'])
def get_none_alg_token():
    payload = {
        'isAdmin': True,
        'exp': (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).timestamp()
    }

    header = {
        'alg': 'none',
        'typ': 'JWT'
    }

    encoded_header = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    encoded_payload = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")

    token = f"{encoded_header}.{encoded_payload}."
    return jsonify({'token': token})

@app.route('/healthcheck', methods=['GET'])
def health_check():
    return make_response('ok', 200)

if __name__ == '__main__':
    app.run(debug=True)
EOM

cat << 'EOM' > /home/ec2-user/requirements.txt
flask==3.0.3
pyjwt==2.8.0
EOM

cd /home/ec2-user
pip3 install -r requirements.txt

sed -i 's/include \/etc\/nginx\/conf.d\/\*.conf;/#include \/etc\/nginx\/conf.d\/\*.conf;/' /etc/nginx/nginx.conf
sed -i 's/include \/etc\/nginx\/default.d\/\*.conf;/#include \/etc\/nginx\/default.d\/\*.conf;/' /etc/nginx/nginx.conf
sed -i '45i \        location / {' /etc/nginx/nginx.conf
sed -i '46i \                proxy_pass http://127.0.0.1:5000;' /etc/nginx/nginx.conf
sed -i '47i \        }' /etc/nginx/nginx.conf

systemctl restart nginx 
nohup python3 main.py &

EOF

  tags = {
    Name = "wsi-priv-a-bastion"
  }
}

# Private Instance B 생성
resource "aws_instance" "wsi-bastion-private-b-instance" {
  subnet_id              = aws_subnet.private-subnet-b.id
  vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.keypair.key_name
  user_data = <<EOF
#!/bin/bash
yum install python3-pip -y 
yum install nginx -y 
yum install docker -y
systemctl enable --now nginx 
usermod -aG docker ec2-user
systemctl enable --now docker 
cat << 'EOM' > /home/ec2-user/main.py
from flask import Flask, request, jsonify, make_response
import jwt
import datetime
import base64
import json

app = Flask(__name__)

SECRET_KEY = 'jwtsecret'

@app.route('/v1/token', methods=['GET'])
def get_token():
    payload = {
        'isAdmin': False,
        'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return jsonify({'token': token})

@app.route('/v1/token/verify', methods=['GET'])
def verify_token():
    token = request.headers.get('Authorization')
    if not token:
        return make_response('Token is missing', 403)

    decoded = jwt.decode(token, options={"verify_signature": False})
    isAdmin = decoded.get('isAdmin', False)
    if isAdmin:
        return 'You are admin!'
    else:
        return 'You are not permitted'

@app.route('/v1/token/none', methods=['GET'])
def get_none_alg_token():
    payload = {
        'isAdmin': True,
        'exp': (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).timestamp()
    }

    header = {
        'alg': 'none',
        'typ': 'JWT'
    }

    encoded_header = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    encoded_payload = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")

    token = f"{encoded_header}.{encoded_payload}."
    return jsonify({'token': token})

@app.route('/healthcheck', methods=['GET'])
def health_check():
    return make_response('ok', 200)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
EOM

cat << 'EOM' > /home/ec2-user/requirements.txt
flask==3.0.3
pyjwt==2.8.0
EOM

cd /home/ec2-user
pip3 install -r requirements.txt

sed -i 's/include \/etc\/nginx\/conf.d\/\*.conf;/#include \/etc\/nginx\/conf.d\/\*.conf;/' /etc/nginx/nginx.conf
sed -i 's/include \/etc\/nginx\/default.d\/\*.conf;/#include \/etc\/nginx\/default.d\/\*.conf;/' /etc/nginx/nginx.conf
sed -i '45i \        location / {' /etc/nginx/nginx.conf
sed -i '46i \                proxy_pass http://127.0.0.1:5000;' /etc/nginx/nginx.conf
sed -i '47i \        }' /etc/nginx/nginx.conf

systemctl restart nginx 
nohup python3 main.py &

EOF

  tags = {
    Name = "wsi-priv-b-bastion"
  }
}

# ALB 생성
resource "aws_lb" "wsi_alb" {
  name               = "wsi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wsi-bastion.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  tags = {
    Name = "wsi-alb"
  }
}

# 타겟 그룹 생성
resource "aws_lb_target_group" "wsi_target_group" {
  name     = "wsi-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    interval            = 30
    path                = "/healthcheck"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "wsi-target-group"
  }
}

# 타겟 그룹에 인스턴스 등록
resource "aws_lb_target_group_attachment" "wsi_bastion_private_a" {
  target_group_arn = aws_lb_target_group.wsi_target_group.arn
  target_id        = aws_instance.wsi-bastion-private-a-instance.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "wsi_bastion_private_b" {
  target_group_arn = aws_lb_target_group.wsi_target_group.arn
  target_id        = aws_instance.wsi-bastion-private-b-instance.id
  port             = 80
}

# ALB 리스너 생성
resource "aws_lb_listener" "wsi_listener" {
  load_balancer_arn = aws_lb.wsi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wsi_target_group.arn
  }
}

resource "aws_wafv2_web_acl" "wsi_waf" {
  name        = "wsi-waf"
  description = "WAF configuration for wsi-waf"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "test"
    sampled_requests_enabled   = true
  }

  custom_response_body {
    key          = "test-body"  # 이 부분을 추가해야 합니다.
    content_type = "TEXT_PLAIN"
    content      = "Blocked by WAF"
  }

  rule {
    name     = "BlockRule"
    priority = 0
    action {
      block {
        custom_response {
          response_code          = 401
          custom_response_body_key = "test-body"
        }
      }
    }
    statement {
      or_statement {
        statement {
          byte_match_statement {
            search_string          = "eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0"
            positional_constraint  = "CONTAINS"
            field_to_match {
              single_header {
                name = "authorization"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            search_string          = "eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0"
            positional_constraint  = "CONTAINS"
            field_to_match {
              single_header {
                name = "authorization"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "test"
      sampled_requests_enabled   = true
    }
  }
}

# WAF를 ALB에 연동
resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = aws_lb.wsi_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.wsi_waf.arn
}