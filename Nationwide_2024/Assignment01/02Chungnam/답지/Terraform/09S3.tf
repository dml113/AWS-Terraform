resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

# S3 버킷 생성
resource "aws_s3_bucket" "my_bucket" {
  bucket = "${random_pet.bucket_name.id}-gmst" # 고유한 버킷 이름으로 변경
  acl    = "private"
}

# 파일 내용 작성 및 S3 업로드
resource "aws_s3_bucket_object" "cluster_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/cluster.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: wsc2024-eks-cluster
  version: "1.29"
  region: us-east-1

secretsEncryption:
  keyARN: ${aws_kms_key.eks_kms_key.arn}

vpc:
  id: ${aws_vpc.wsc2024-prod-vpc.id}
  subnets:
    private:
      private-a: { id: ${aws_subnet.wsc2024-prod-app-sn-a.id} }
      private-b: { id: ${aws_subnet.wsc2024-prod-app-sn-b.id} }
      
iamIdentityMappings:
  - arn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root # kubectl edit configmap aws-auth -n kube-system
    groups:                                  # edit to arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root -> arn:aws:iam::${data.aws_caller_identity.current.account_id}:root
      - system:masters
    username: root-admin
iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true

managedNodeGroups:
  - name: wsc2024-db-application-ng
    labels: { app: db }
    instanceType: t3.medium
    instanceName: wsc2024-db-application-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true
      
  - name: wsc2024-other-ng
    labels: { app: other }
    instanceType: t3.medium
    instanceName: wsc2024-other-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]
EOF
}

resource "aws_s3_bucket_object" "deployment_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/deployment.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-deploy
  namespace: wsc2024
  labels:
    app: customer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: customer
  template:
    metadata:
      labels:
        app: customer
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app
                operator: In
                values:
                - db
      containers:
        - name: customer-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/customer-repo:latest
          lifecycle: 
            preStop: 
              exec:
                command: ["sleep", "20"]
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 250m
              memory: 500Mi
      restartPolicy: Always

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-deploy
  namespace: wsc2024
  labels:
    app: product
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product
  template:
    metadata:
      labels:
        app: product
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app
                operator: In
                values:
                - db
      containers:
        - name: product-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/product-repo:latest
          lifecycle: 
            preStop: 
              exec:
                command: ["sleep", "20"]
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 250m
              memory: 500Mi
      restartPolicy: Always

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-deploy
  namespace: wsc2024
  labels:
    app: order
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order
  template:
    metadata:
      labels:
        app: order
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app
                operator: In
                values:
                - db
      containers:
        - name: order-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/order-repo:latest
          lifecycle: 
            preStop: 
              exec:
                command: ["sleep", "20"]
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 250m
              memory: 500Mi
      restartPolicy: Always
EOF
}

resource "aws_s3_bucket_object" "svc_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/svc.yaml"
  source  = "./manifest/svc.yaml"
}

resource "aws_s3_bucket_object" "ingress_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/ingress.yaml"
  source  = "./manifest/ingress.yaml"
}

resource "aws_s3_bucket_object" "gw_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/gw.yaml"
  source  = "./manifest/gw.yaml"
}

resource "aws_s3_bucket_object" "hr_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/hr.yaml"
  source  = "./manifest/hr.yaml"
}

resource "aws_s3_bucket_object" "tgp_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/tgp.yaml"
  source  = "./manifest/tgp.yaml"
}

resource "aws_s3_bucket_object" "customer_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "app/customer"
  source  = "./application/binary/customer"
}

resource "aws_s3_bucket_object" "order_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "app/order"
  source  = "./application/binary/order"
}

resource "aws_s3_bucket_object" "product_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "app/product"
  source  = "./application/binary/product"
}
##########################################################################

resource "random_string" "random_name" {
  length  = 4
  special = false
  upper   = false
  number  = false 
}

# S3 버킷 생성
resource "aws_s3_bucket" "static_bucket" {
  bucket = "wsc2024-s3-static-${random_string.random_name.result}" # 고유한 버킷 이름으로 변경
  acl    = "private"
}

resource "aws_s3_bucket_object" "index_upload" {
  bucket  = aws_s3_bucket.static_bucket.id
  key     = "index.html"
  source  = "./application/index.html"
}
###############################################################################

resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.my_bucket.id} --recursive"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    aws_s3_bucket_object.deployment_upload,
    aws_s3_bucket_object.svc_upload,
    aws_s3_bucket_object.ingress_upload,
    aws_s3_bucket_object.customer_upload,
    aws_s3_bucket_object.order_upload,
    aws_s3_bucket_object.product_upload,
    aws_rds_cluster_instance.aurora_reader,
    aws_rds_cluster_instance.aurora_writer
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