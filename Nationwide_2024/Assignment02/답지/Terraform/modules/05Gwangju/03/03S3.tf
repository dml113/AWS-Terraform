resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "${random_pet.bucket_name.id}-gmst" # 고유한 버킷 이름으로 변경
  acl    = "private"
}

# 로컬 폴더 경로와 S3 프리픽스 설정
locals {
  upload_dir = "./files/05Gwangju/03/application" 
  s3_prefix  = "application/"
}

# 파일 업로드
resource "aws_s3_bucket_object" "upload_files" {
  for_each = fileset(local.upload_dir, "**/*")

  bucket = aws_s3_bucket.my_bucket.id
  key    = "${local.s3_prefix}${each.value}"
  source = "${local.upload_dir}/${each.value}"
  etag   = filemd5("${local.upload_dir}/${each.value}")
}

resource "aws_s3_bucket_object" "cluster_upload" {
  bucket = aws_s3_bucket.my_bucket.id
  key = "manifest/cluster.yaml"
  content = <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: skills-eks-cluster
  version: "1.29"
  region: ap-northeast-2

vpc:
  subnets:
    public:
      public-a: { id: ${aws_subnet.public_subnet_a.id} }
      public-b: { id: ${aws_subnet.public_subnet_b.id} }
    private:
      private-a: { id: ${aws_subnet.private_subnet_a.id} }
      private-b: { id: ${aws_subnet.private_subnet_b.id} }
      
iamIdentityMappings:
  - arn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root # kubectl edit configmap aws-auth -n kube-system
    groups:                                  # edit to arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root -> arn:aws:iam::${data.aws_caller_identity.current.account_id}:root  
      - system:masters
    username: root-admin
    noDuplicateARNs: true # prevents shadowing of ARNs

managedNodeGroups:
  - name: warm-app-ngA
    labels: { app: python }
    instanceType: t3.small
    instanceName: warm-app-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeType: gp2
    volumeEncrypted: true
EOF
}

resource "aws_s3_bucket_object" "deployment_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/deployment.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-a
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-a
  template:
    metadata:
      labels:
        app: service-a
    spec:
      containers:
        - name: service-a
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:a
          volumeMounts:
            - name: applog
              mountPath: /log
        - name: fluent-bit
          image: fluent/fluent-bit:latest
          volumeMounts:
            - name: applog
              mountPath: /var/log/service-a/
              readOnly: true
            - name: fluent-bit-config
              mountPath: /fluent-bit/etc
      volumes:
        - name: applog
          emptyDir: {}
        - name: fluent-bit-config
          configMap:
            name: fluent-bit-config
      restartPolicy: Always
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-b
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-b
  template:
    metadata:
      labels:
        app: service-b
    spec:
      containers:
        - name: service-b
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:b
          volumeMounts:
            - name: applog
              mountPath: /log
        - name: fluent-bit
          image: fluent/fluent-bit:latest
          volumeMounts:
            - name: applog
              mountPath: /var/log/service-b/
              readOnly: true
            - name: fluent-bit-config
              mountPath: /fluent-bit/etc
      volumes:
        - name: applog
          emptyDir: {}
        - name: fluent-bit-config
          configMap:
            name: fluent-bit-config
      restartPolicy: Always
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-c
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-c
  template:
    metadata:
      labels:
        app: service-c
    spec:
      containers:
        - name: service-c
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/service:c
          volumeMounts:
            - name: applog
              mountPath: /log
        - name: fluent-bit
          image: fluent/fluent-bit:latest
          volumeMounts:
            - name: applog
              mountPath: /var/log/service-c/
              readOnly: true
            - name: fluent-bit-config
              mountPath: /fluent-bit/etc
      volumes:
        - name: applog
          emptyDir: {}
        - name: fluent-bit-config
          configMap:
            name: fluent-bit-config
      restartPolicy: Always
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: app
data:
  fluent-bit.conf: |-
    [SERVICE]
        HTTP_Server    On
        HTTP_Listen    0.0.0.0
        HTTP_PORT      2020
        Flush          1
        Daemon         Off
        Log_Level      debug

    [INPUT]
        Name              tail
        Tag               service-a
        Path              /var/log/service-a/*
        Refresh_Interval  5
        Rotate_Wait       10

    [INPUT]
        Name              tail
        Tag               service-b
        Path              /var/log/service-b/*
        Refresh_Interval  5
        Rotate_Wait       10

    [INPUT]
        Name              tail
        Tag               service-c
        Path              /var/log/service-c/*
        Refresh_Interval  5
        Rotate_Wait       10

    [OUTPUT]
        Name              forward
        Match             service-a
        Host              fluentd-svc.fluentd.svc.cluster.local
        Port              24224

    [OUTPUT]
        Name              forward
        Match             service-b
        Host              fluentd-svc.fluentd.svc.cluster.local
        Port              24224

    [OUTPUT]
        Name              forward
        Match             service-c
        Host              fluentd-svc.fluentd.svc.cluster.local
        Port              24224
EOF
}

resource "aws_s3_bucket_object" "fluentd_upload" {
  source = "./files/05Gwangju/03/manifest/fluentd.yaml"
  key = "manifest/fluentd.yaml"
  bucket = aws_s3_bucket.my_bucket.id
}

resource "null_resource" "wait_for_delay" {
  provisioner "local-exec" {
    command     = "sleep 300"
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.my_bucket.id} --recursive"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.wait_for_delay,
  ]
}

resource "null_resource" "delete_bucket" {
  provisioner "local-exec" {
    command = "aws s3api delete-bucket --bucket ${aws_s3_bucket.my_bucket.id}"
  }

  depends_on = [
    null_resource.empty_bucket,
  ]
}