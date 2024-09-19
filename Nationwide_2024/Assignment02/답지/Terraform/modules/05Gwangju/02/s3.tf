resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "${random_pet.bucket_name.id}-gmst" 
  acl    = "private"
}

resource "aws_s3_bucket_object" "app_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "application/main.py"
  source  = "./files/05Gwangju/02/application/main.py"
}

resource "aws_s3_bucket_object" "req_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "application/requirements.txt"
  source  = "./files/05Gwangju/02/application/requirements.txt"
}

resource "aws_s3_bucket_object" "doc_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "application/Dockerfile"
  source  = "./files/05Gwangju/02/application/Dockerfile"
}

resource "aws_s3_bucket_object" "cluster_upload" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "manifest/cluster.yaml" # 업로드할 파일의 S3 경로와 이름
  content = <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: warm-eks-clusterA
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

iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true

managedNodeGroups:
  - name: warm-app-ngA
    labels: { app: nga }
    instanceType: t3.medium
    instanceName: warm-app-node
    desiredCapacity: 2
    minSize: 2
    maxSize: 20
    privateNetworking: true
    volumeType: gp2
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        awsLoadBalancerController: true
        autoScaler: true
EOF
}