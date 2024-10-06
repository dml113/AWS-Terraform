resource "aws_s3_bucket" "ap_wsi_static" {
  provider = aws.ap
  bucket   = "ap-wsi-static-${random_string.suffix_ap.result}"
  acl      = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.ap.arn
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.s3_replication_role.arn

    rules {
      id     = "replication-rule"
      status = "Enabled"

      filter {
        prefix = ""
      }

      destination {
        bucket        = aws_s3_bucket.us_wsi_static.arn
        storage_class = "STANDARD"
        replica_kms_key_id = aws_kms_key.us.arn
      }

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }
    }
  }
}

resource "aws_s3_bucket" "us_wsi_static" {
  provider = aws.us
  bucket = "us-wsi-static-${random_string.suffix_us.result}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.us.arn
      }
    }
  }
}

# resource "aws_cloudfront_distribution" "s3_distribution" {
#   origin {
#     domain_name = aws_s3_bucket.ap_wsi_static.bucket_regional_domain_name
#     origin_id   = "S3-ap-wsi-static"

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
#     }
#   }

#   origin {
#     domain_name = aws_s3_bucket.us_wsi_static.bucket_regional_domain_name
#     origin_id   = "S3-us-wsi-static"

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
#     }
#   }

#   enabled             = true
#   is_ipv6_enabled     = false
#   comment             = "S3 static content distribution"
#   default_root_object = "index.html"

#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "S3-ap-wsi-static"

#     forwarded_values {
#       query_string = true
#       cookies {
#         forward = "none"
#       }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   ordered_cache_behavior {
#     path_pattern = "/alb/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "ALB"

#     forwarded_values {
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 0
#     max_ttl                = 0
#   }

#   custom_error_response {
#     error_code            = 503
#     response_code         = 503
#     response_page_path    = "/error-pages/503.html"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   tags = {
#     Name = "wsi-cdn"
#   }
# }

resource "aws_iam_role" "s3_replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication_policy" {
  role = aws_iam_role.s3_replication_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetReplicationConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectRetention",
                "s3:GetObjectLegalHold"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.ap_wsi_static.arn}",
                "${aws_s3_bucket.ap_wsi_static.arn}/*"
            ]
        },
        {
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:GetObjectVersionTagging",
                "s3:ObjectOwnerOverrideToBucketOwner"
            ],
            "Effect": "Allow",
            "Condition": {
                "StringLikeIfExists": {
                    "s3:x-amz-server-side-encryption": [
                        "aws:kms",
                        "aws:kms:dsse",
                        "AES256"
                    ]
                }
            },
            "Resource": [
                "${aws_s3_bucket.us_wsi_static.arn}/*"
            ]
        },
        {
            "Action": [
                "kms:Decrypt"
            ],
            "Effect": "Allow",
            "Condition": {
                "StringLike": {
                    "kms:ViaService": "s3.ap-northeast-2.amazonaws.com",
                    "kms:EncryptionContext:aws:s3:arn": [
                        "${aws_s3_bucket.ap_wsi_static.arn}/*"
                    ]
                }
            },
            "Resource": [
                "${aws_kms_key.ap.arn}"
            ]
        },
        {
            "Action": [
                "kms:Encrypt"
            ],
            "Effect": "Allow",
            "Condition": {
                "StringLike": {
                    "kms:ViaService": [
                        "s3.us-east-1.amazonaws.com"
                    ],
                    "kms:EncryptionContext:aws:s3:arn": [
                       "${aws_s3_bucket.us_wsi_static.arn}/*"
                    ]
                }
            },
            "Resource": [
                "${aws_kms_key.us.arn}"
            ]
         }
      ]
   })  
}

resource "random_string" "suffix_ap" {
  length  = 4
  special = false
  upper   = false
  number  = false
}

resource "random_string" "suffix_us" {
  length  = 4
  special = false
  upper   = false
  number  = false
}

resource "random_pet" "bucket_test" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "gongma-${random_pet.bucket_test.id}-gmst-uploadfile"
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
  region: ap-northeast-2

vpc:
  subnets:
    private:
      private-subnet-a: { id: ${aws_subnet.wsi_app_a.id} }
      private-subnet-b: { id: ${aws_subnet.wsi_app_b.id} }

iamIdentityMappings:
  - arn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/root # kubectl edit configmap aws-auth -n kube-system
    groups:                                  # edit to arn:aws:iam::073762821266:role/root -> arn:aws:iam::073762821266:root
      - system:masters
    username: root-admin
    noDuplicateARNs: true # prevents shadowing of ARNs

iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true

managedNodeGroups:
  - name: wsi-addon-nodegroup
    labels: { role: addon }
    instanceType: t4g.large
    instanceName: wsi-addon-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeEncrypted: true
    amiFamily: Bottlerocket
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true

  - name: wsi-app-nodegroup
    labels: { role: app }
    instanceType: m5.xlarge
    instanceName: wsi-app-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeEncrypted: true
    amiFamily: Bottlerocket
    disablePodIMDS: true
      #    iam:
      #      withAddonPolicies:
      #        imageBuilder: true
      #        autoScaler: true
      #        cloudWatch: true

cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator", "controllerManager", "scheduler"]

secretsEncryption:
  keyARN: ${aws_kms_key.kubernetes.arn}
EOF
}

resource "aws_s3_bucket_object" "deployment_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/deployment.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer
  namespace: wsi
  labels:
    app: customer
  annotations:
    reloader.stakater.com/auto: "true"
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
              - key: role
                operator: In
                values:
                - app
      containers:
        - name: customer-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/customer:latest
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 500m
              memory: 1000Mi
            limits:
              cpu: 500m
              memory: 1000Mi
          env:
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: secrets-manager-secret
                  key: MYSQL_USER
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-manager-secret
                  key: MYSQL_PASSWORD
      serviceAccountName: admin-sa
      restartPolicy: Always

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: product
  namespace: wsi
  labels:
    app: product
  annotations:
    reloader.stakater.com/auto: "true"
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
              - key: role
                operator: In
                values:
                - app
      containers:
        - name: product-container
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/product:latest
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 500m
              memory: 1000Mi
            limits:
              cpu: 500m
              memory: 1000Mi
          env:
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: secrets-manager-secret
                  key: MYSQL_USER
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-manager-secret
                  key: MYSQL_PASSWORD
      serviceAccountName: admin-sa
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
          image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/order:latest
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 500m
              memory: 1000Mi
            requests:
              cpu: 500m
              memory: 1000Mi
      serviceAccountName: admin-sa
      restartPolicy: Always
EOF
}

resource "aws_s3_bucket_object" "ss_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "manifest/ss.yaml"
  source  = "./manifest/ss.yaml"
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

resource "aws_s3_bucket_object" "fluent-bit_yaml_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "logging/fluent-bit.yaml"
  source  = "./logging/fluent-bit.yaml"
}

resource "aws_s3_bucket_object" "fluent_bit_file_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "logging/fluent-bit.sh"
  source  = "./logging/fluent-bit.sh"
}

resource "aws_s3_bucket_object" "fluentd_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "logging/cwagent-fluentd-quickstart-enhanced.yaml"
  source  = "./logging/cwagent-fluentd-quickstart-enhanced.yaml"
}

resource "aws_s3_bucket_object" "order_logs_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "logging/aws-logging-cloudwatch-configmap.yaml"
  source  = "./logging/aws-logging-cloudwatch-configmap.yaml"
}

resource "aws_s3_bucket_object" "customer_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/customer"
  source  = "./backend/customer"
}

resource "aws_s3_bucket_object" "order_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/order"
  source  = "./backend/order"
}

resource "aws_s3_bucket_object" "product_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app/product"
  source  = "./backend/product"
}

resource "aws_s3_bucket_object" "css_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "static/css/bootstrap.min.css"
  source  = "./static/css/bootstrap.min.css"
}

resource "aws_s3_bucket_object" "js_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "static/js/main.js"
  source  = "./static/js/main.js"
}

resource "aws_s3_bucket_object" "index_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "static/index.html"
  source  = "./static/index.html"
}

resource "aws_s3_bucket_object" "error_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "error/50x.html"
  source  = "./static/error/50x.html"
}