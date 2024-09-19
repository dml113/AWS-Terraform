resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "gongma-${random_pet.bucket_name.id}-gmst-uploadfile"
}

resource "aws_s3_bucket_object" "cluster_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/cluster.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: wsi-eks-cluster
  version: "1.29"
  region: ${var.region}

vpc:
  id: ${aws_vpc.vpc.id}
  subnets:
    private:
      private-a: { id: ${aws_subnet.app-subnet-a.id} }
      private-b: { id: ${aws_subnet.app-subnet-b.id} }

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
  - name: wsi-app-nodegroup
    labels: { app: db }
    instanceType: t3.large
    instanceName: wsi-app-nodegroup
    desiredCapacity: 4
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true

  - name: wsi-addon-nodegroup
    labels: { app: other }
    instanceType: t3.medium
    instanceName: wsi-addon-nodegroup
    desiredCapacity: 4
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
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/deployment.yaml" 
  content = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer
  namespace: wsi
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
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/customer-ecr:latest
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
  name: product
  namespace: wsi
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
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/product-ecr:latest
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
  name: order
  namespace: wsi
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
      containers:
        - name: order-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/order-ecr:latest
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
      serviceAccountName: admin-sa
      restartPolicy: Always
EOF
}

resource "aws_s3_bucket_object" "svc_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/svc.yaml"
  source  = "./manifest/svc.yaml"
}

resource "aws_s3_bucket_object" "ingress_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/ingress.yaml"
  source  = "./manifest/ingress.yaml"
}

resource "aws_s3_bucket_object" "fluent_bit_shell" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "/logging/fluent-bit.sh"
  source  = "./logging/fluent-bit.sh"
}

resource "aws_s3_bucket_object" "fluent_bit" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "/logging/fluent-bit.yaml"
  source  = "./logging/fluent-bit.yaml"
}

resource "aws_s3_bucket_object" "customer_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/customer"
  source  = "./application/binary/customer"
}

resource "aws_s3_bucket_object" "order_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/order"
  source  = "./application/binary/order"
}

resource "aws_s3_bucket_object" "product_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/product"
  source  = "./application/binary/product"
}

variable "number" {
    type = string
}

resource "aws_s3_bucket" "static_bucket" {
  bucket = "apne2-wsi-static-${var.number}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_kms.arn
      }
    }
  }
}

resource "aws_s3_bucket_object" "index_upload" {
  bucket  = aws_s3_bucket.static_bucket.id
  key     = "/static/index.html"
  source  = "./static/index.html"

  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.s3_kms.arn
}

###############################################################################

resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.bucket.id} --recursive"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    aws_rds_cluster_instance.wsi_aurora_mysql_instance
  ]
}

resource "null_resource" "delete_bucket" {
  provisioner "local-exec" {
    command = "aws s3api delete-bucket --bucket ${aws_s3_bucket.bucket.id}"
  }

  depends_on = [
    null_resource.empty_bucket,
  ]
}