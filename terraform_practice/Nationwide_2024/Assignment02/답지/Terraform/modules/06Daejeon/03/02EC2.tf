resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pair" {
  key_name   = "wsi-app-pair2.pem"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "file" {
  filename        = "wsi-app-pair2.pem"
  content         = tls_private_key.key.private_key_pem
}

resource "aws_security_group" "sg" {
  name        = "wsi-app-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "wsi-bastion-ec2-sg"
  }
}

resource "aws_security_group_rule" "ingress22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

data "aws_iam_policy_document" "document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "role" {
name               = "03-wsi-bastion-ec2-role2"
  assume_role_policy = data.aws_iam_policy_document.document.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "03-wsi-bastion-ec2-role2"
  role = aws_iam_role.role.name
}

resource "aws_instance" "instance" {
  security_groups             = [aws_security_group.sg.id]
  ami                         = "ami-0b8414ae0d8d8b4cc"
  subnet_id                   = aws_subnet.subnet_a.id
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.pair.key_name

  user_data                   = <<-EOF
#!/bin/bash

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/bin/

curl -O --silent --location https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/bin/

yum install docker -y
systemctl enable docker
systemctl restart docker
usermod -aG docker ec2-user
systemctl restart docker

aws ecr create-repository --repository-name wsi-repo

mkdir /home/ec2-user/2024/

cat << "application" > /home/ec2-user/2024/app.py
from flask import Flask, request, jsonify, abort
import datetime
import logging

app = Flask(__name__)

class KSTFormatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        kst_now = datetime.datetime.utcnow() + datetime.timedelta(hours=9)
        if datefmt:
            return kst_now.strftime(datefmt)
        return kst_now.strftime('%Y-%m-%d %H:%M:%S,%f')[:-3]

access_log_format = '%(asctime)s - - %(client_ip)s %(port)s %(method)s %(path)s %(status)s'
access_log_formatter = KSTFormatter(access_log_format)

access_log_handler = logging.FileHandler('/logs/app.log')
access_log_handler.setFormatter(access_log_formatter)

access_log = logging.getLogger('access')
access_log.setLevel(logging.INFO)
access_log.addHandler(access_log_handler)

@app.after_request
def after_request(response):
    extra = {
        'client_ip': request.remote_addr,
        'port': request.environ['SERVER_PORT'],
        'method': request.method,
        'path': request.path,
        'status': response.status_code
    }
    access_log.info('', extra=extra)
    return response

@app.route('/2xx', methods=['GET'])
def get_2xx():
    try:
        ret = {"status": "200"}
        return jsonify(ret), 200
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.route('/3xx', methods=['GET'])
def get_3xx():
    try:
        ret = {"status": "300"}
        return jsonify(ret), 300
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.route('/4xx', methods=['GET'])
def get_4xx():
    try:
        ret = {"status": "400"}
        return jsonify(ret), 400
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.route('/5xx', methods=['GET'])
def get_5xx():
    try:
        ret = {"status": "500"}
        return jsonify(ret), 500
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.route('/healthz', methods=['GET'])
def get_healthz():
    try:
        ret = {"status": "ok"}
        return jsonify(ret), 200
    except Exception as e:
        app.logger.error(e)
        abort(500)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
application

chmod +x /home/ec2-user/2024/app.py

cat << "dockerfile" > /home/ec2-user/2024/Dockerfile
FROM python:alpine

WORKDIR /app/

COPY app.py /app/app.py

RUN apk update
RUN apk add curl 

RUN pip3 install flask

RUN mkdir /logs/

CMD ["python", "app.py"]
dockerfile

cat << "ct" > /home/ec2-user/2024/cluster.yml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: wsi-eks-cluster
  version: "1.29"
  region: ap-northeast-2
vpc:
  subnets:
    public:
      public-a: { id: ${aws_subnet.subnet_a.id} }
      public-b: { id: ${aws_subnet.subnet_b.id} }
iamIdentityMappings:
  - arn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root # kubectl edit configmap aws-auth -n kube-system
    groups:                                  # edit to arn:aws:iam::073762821266:role/root -> arn:aws:iam::073762821266:root
      - system:masters
    username: root-admin
    noDuplicateARNs: true # prevents shadowing of ARNs
managedNodeGroups:
  - name: wsi-eks-ng
    labels: { daejeon: wsi }
    instanceType: t3.large
    instanceName: wsi-eks-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true
ct

cat << "dep" > /home/ec2-user/2024/deploy.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wsi-dpm
  namespace: wsi-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wsi-cnt
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: wsi-cnt
      labels:
        app: wsi-cnt
    spec:
      containers:
      - name: wsi-cnt
        image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-repo:latest
        volumeMounts:
        - name: applog
          mountPath: /logs
      - name: fluent-bit-cnt
        image: fluent/fluent-bit:latest
        volumeMounts:
        - name: applog
          mountPath: /logs
        - name: log-volume
          mountPath: /fluent-bit/etc
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      volumes:
      - name: applog
        emptyDir: {}
      - name: log-volume
        configMap:
          name: fluent-bit-config
dep

aws s3 cp s3://${aws_s3_bucket.bucket.id}/configmap.yml /home/ec2-user/2024/

cd /home/ec2-user/2024/

aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t wsi-repo .
docker tag wsi-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-repo:latest
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-repo:latest

eksctl create cluster -f /home/ec2-user/2024/cluster.yml

kubectl create ns wsi-ns

kubectl apply -f /home/ec2-user/2024/configmap.yml
sleep 10
kubectl apply -f /home/ec2-user/2024/deploy.yml

ROLE_NAME=$(aws eks describe-nodegroup --cluster-name wsi-eks-cluster --nodegroup-name wsi-eks-ng --query "nodegroup.nodeRole" --output text | awk -F'/' '{print $2}')
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

EOF
  tags = {
    Name = "wsi-bastion-ec2"
  }
}