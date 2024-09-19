resource "aws_iam_role" "example_role" {
    name = "wsi-role-bastion3"

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
    name = "04ec2_instance_profile3"
    role = aws_iam_role.example_role.name
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    key_name   = "gyeongbuk-key3"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "gyeongbuk3.pem"
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

resource "aws_eip" "wsi-eip-bastion" {
  instance = aws_instance.wsi-bastion-instance.id
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "wsi-eip-bastion"
  }
}

resource "aws_instance" "wsi-bastion-instance" {
    subnet_id = aws_subnet.public-subnet-a.id
    vpc_security_group_ids = [aws_security_group.default_groups.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 
    instance_type = "t3.small"
    key_name = aws_key_pair.keypair.key_name          
    user_data = <<EOF
#!/bin/bash
yum install curl -y --allowerasing
EOF

    tags = {
        Name = "wsi-bastion"
    }
}

resource "aws_instance" "wsi-app-instance" {
    subnet_id = aws_subnet.private-subnet-a.id
    vpc_security_group_ids = [aws_security_group.default_groups.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 
    instance_type = "t3.small"
    key_name = aws_key_pair.keypair.key_name          
    user_data = <<EOF
#!/bin/bash
yum install python3-pip -y
pip3 install flask

cat << 'EOM' > /home/ec2-user/app.py 
from flask import Flask, request
import logging
import time
import os

app = Flask(__name__)

log_dir = 'log'
log_file = 'app.log'

if not os.path.exists(log_dir):
    os.makedirs(log_dir)

formatter = logging.Formatter('%(message)s')

file_handler = logging.FileHandler(os.path.join(log_dir, log_file))
file_handler.setFormatter(formatter)

logger = logging.getLogger('customLogger')
logger.setLevel(logging.INFO)

logger.addHandler(file_handler)

def log_request_info():
    client_ip = request.remote_addr
    timestamp = time.strftime('%d/%b/%Y:%H:%M:%S %z')
    method = request.method
    path = request.path
    protocol = request.environ.get('SERVER_PROTOCOL')
    status_code = 200
    user_agent = request.headers.get('User-Agent')

    log_message = (f'{client_ip} - [{timestamp}] "{method} {path} {protocol}" '
                   f'{status_code} "{user_agent}"')

    logger.info(log_message)

@app.route('/log', methods=['GET'])
def log_request():
    log_request_info()
    return "Log entry created", 200

@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    log_request_info()
    return "status: ok", 200

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0')
EOM

cd /home/ec2-user
nohup python3 app.py &

curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
sudo systemctl enable --now fluent-bit
sudo ln -s /opt/fluent-bit/bin/fluent-bit /usr/local/bin/fluent-bit

sleep 1700

cat << 'EOM' > /home/ec2-user/fluent-bit.conf
[INPUT]
    Name        tail
    Path        /home/ec2-user/log/app.log

[FILTER]
    Name   grep
    Match  *
    Exclude log /healthcheck

[OUTPUT]
    Name            opensearch
    Match           *
    Host            ${aws_opensearch_domain.wsi_opensearch.endpoint}
    Port            443
    HTTP_User       admin
    HTTP_Passwd     Password01!
    Index           app-log
    tls             On
    tls.verify      Off
    Replace_Dots    On
    Suppress_Type_Name On
EOM

cd /home/ec2-user
mv /home/ec2-user/fluent-bit.conf /etc/fluent-bit//fluent-bit.conf

/usr/local/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf &

EOF

    tags = {
        Name = "wsi-app"
    }
}