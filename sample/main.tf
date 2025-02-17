################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################

# Import the VPC module to create a VPC
module "vpc" {
  source     = "./modules/vpc"    # Path to the VPC module
  vpc_name   = "vpc"              # Name of the VPC
  vpc_cidr   = "10.0.0.0/16"      # CIDR block for the VPC
  create_igw = true               # No Internet Gateway for this VPC

  # Subnet definitions for the database VPC
  subnets = {
    "public-subnet-a"   = { name = "public-subnet-a", cidr = "10.0.0.0/24", az = "ap-northeast-2a", public = true }
    "public-subnet-b"   = { name = "public-subnet-b", cidr = "10.0.1.0/24", az = "ap-northeast-2b", public = true }    
    "app-subnet-a"      = { name = "app-subnet-a", cidr = "10.0.2.0/24", az = "ap-northeast-2a", public = false }
    "app-subnet-b"      = { name = "app-subnet-b", cidr = "10.0.3.0/24", az = "ap-northeast-2b", public = false }
    "db-subnet-a"       = { name = "db-subnet-a", cidr = "10.0.4.0/24", az = "ap-northeast-2a", public = false }
    "db-subnet-b"       = { name = "db-subnet-b", cidr = "10.0.5.0/24", az = "ap-northeast-2b", public = false }    
  }

  # NAT Gateway configuration is omitted since there are no public subnets
  nat_gateways = { 
    "app-natgw-a"       = { name = "app-natgw-a", subnet_id = "public-subnet-a" }
    "app-natgw-b"       = { name = "app-natgw-b", subnet_id = "public-subnet-b" } 
    }

  # Route table definitions for internal routing
  route_tables = {
    "public-rt"         = "public-rt"
    "app-rt-a"          = "app-rt-a"
    "app-rt-b"          = "app-rt-b"
    "db-rt-a"           = "db-rt-a"
    "db-rt-b"           = "db-rt-b"    
  }

  # No additional routes are defined
  routes = [
    { 
      rt_name = "public-rt" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = module.vpc.igw_id 
    },
    { 
      rt_name = "app-rt-a" 
      destination_cidr = "0.0.0.0/0" 
      nat_gateway_key ="app-natgw-a"
    },
    { 
      rt_name = "app-rt-b" 
      destination_cidr = "0.0.0.0/0" 
      nat_gateway_key ="app-natgw-b"
    }
  ]

  # Associate subnets with specific route tables
  subnet_associations = {
    "public-subnet-a"      = { subnet_key = "public-subnet-a", route_table_key = "public-rt" }
    "public-subnet-b"      = { subnet_key = "public-subnet-b", route_table_key = "public-rt" }
    "app-subnet-a"         = { subnet_key = "app-subnet-a", route_table_key = "app-rt-a" }
    "app-subnet-b"         = { subnet_key = "app-subnet-b", route_table_key = "app-rt-b" }
    "db-subnet-a"          = { subnet_key = "db-subnet-a", route_table_key = "db-rt-a" }
    "db-subnet-b"          = { subnet_key = "db-subnet-b", route_table_key = "db-rt-b" }    
  }
  
  # VPC endpoints are not created in this example
  # ‼️‼️‼️ 주의사항 ‼️‼️‼️
  # 아래 ENDPOINT는 default Security Group을 사용하므로 Inbound 수정해야 함.

  # vpc_endpoints = {
  #   "s3-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.s3" 
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "dynamodb-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.dynamodb"
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "ec2-endpoint" = {
  #     service_name  = "com.amazonaws.ap-northeast-2.ec2"
  #     type          = "Interface"
  #     subnet_keys   = ["app-subnet-a", "app-subnet-b"]
  #   }
  # }
}

################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = "ami-0a2c043e56e9abcc5"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.subnet_ids["public-subnet-a"]
  key_pair_name          = "bastion-key"
  iam_role_name          = "bastion-role"
  vpc_id                 = module.vpc.vpc_id
  user_data              = filebase64("${path.module}/user_data/user_data.sh")
}

################################################################################################################################################
#                                                                 EKS                                                                          #
################################################################################################################################################

provider "helm" {
  kubernetes {
    host                   = module.eks.eks_endpoint
    cluster_ca_certificate = base64decode(module.eks.eks_certificate_authority_data.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "nginx"

  values = [
    file("${path.module}/helm/nginx-values.yaml")
  ]
}

module "eks" {
  source = "./modules/EKS"
  
  vpc_id             = module.vpc.vpc_id
  eks_cluster_name   = "eks-clusterA"
  region             = "ap-northeast-2"
  allowed_cidrs      = ["10.0.0.0/16"]
  
  vpc_subnets = {
    public  = [module.vpc.subnet_ids["public-subnet-a"], module.vpc.subnet_ids["public-subnet-b"]]
    private = [module.vpc.subnet_ids["app-subnet-a"], module.vpc.subnet_ids["app-subnet-b"]]
  }

  cluster_public_access  = true
  cluster_private_access = true

  managed_node_groups = [
    {
      instance_type      = "t3.medium"
      node_name          = "app-node"
      nodegroup_name     = "app-nodegroup"
      desired_capacity   = 2
      min_size           = 2
      max_size           = 20
# AL2_x86_64 | AL2_x86_64_GPU | AL2_ARM_64 | CUSTOM | BOTTLEROCKET_ARM_64 | BOTTLEROCKET_x86_64 | BOTTLEROCKET_ARM_64_NVIDIA | BOTTLEROCKET_x86_64_NVIDIA | WINDOWS_CORE_2019_x86_64 | WINDOWS_FULL_2019_x86_64 | WINDOWS_CORE_2022_x86_64 | WINDOWS_FULL_2022_x86_64 | AL2023_x86_64_STANDARD | AL2023_ARM_64_STANDARD | AL2023_x86_64_NEURON | AL2023_x86_64_NVIDIA      
      ami_family         = "BOTTLEROCKET_x86_64"
      private_networking = true
      volume_type        = "gp2"
      volume_encrypted   = true
      iam_policies = {
        image_builder                = true
        aws_load_balancer_controller = true
        auto_scaler                  = true
      }
    }
#     {
#       instance_type      = "t3.small"
#       node_name          = "clium-node"
#       nodegroup_name     = "clium-nodegroup"
#       desired_capacity   = 2
#       min_size           = 2
#       max_size           = 20
# # AL2_x86_64 | AL2_x86_64_GPU | AL2_ARM_64 | CUSTOM | BOTTLEROCKET_ARM_64 | BOTTLEROCKET_x86_64 | BOTTLEROCKET_ARM_64_NVIDIA | BOTTLEROCKET_x86_64_NVIDIA | WINDOWS_CORE_2019_x86_64 | WINDOWS_FULL_2019_x86_64 | WINDOWS_CORE_2022_x86_64 | WINDOWS_FULL_2022_x86_64 | AL2023_x86_64_STANDARD | AL2023_ARM_64_STANDARD | AL2023_x86_64_NEURON | AL2023_x86_64_NVIDIA      
#       ami_family         = "BOTTLEROCKET_x86_64"
#       private_networking = true
#       volume_type        = "gp2"
#       volume_encrypted   = true
#       iam_policies = {
#         image_builder                = true
#         aws_load_balancer_controller = true
#         auto_scaler                  = true
#       }
#     }
  ]
  
  eks_addons = ["kube-proxy", "vpc-cni", "coredns", "eks-pod-identity-agent"]
}

# add bastion role to configmap
# kubectl edit cm aws-auth -n kube-system
    # - groups:
    #   - system:masters
    #   rolearn: arn:aws:iam::950274644703:role/bastion-role
    #   username: bastion-user


################################################################################################################################################
#                                                                 RDS                                                                          #
################################################################################################################################################

# module "rds" {
#   source = "./modules/rds"

#   vpc_id             = module.vpc.vpc_id
#   allowed_cidrs      = ["10.0.0.0/16"]

#   db_identifier            = "multi-az-rds"
#   db_engine                = "mysql"
## aurora, aurora-mysql, aurora-postgresql, docdb, mariadb, mysql, neptune, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, and sqlserver-web

#   db_engine_version        = "8.0"
#   db_instance_class        = "db.t3.medium"
#   db_allocated_storage     = 20
#   db_max_allocated_storage = 100
#   multi_az                 = true
#   db_name                  = "mydatabase"
#   db_username              = "admin"
#   db_password              = "SuperSecret123!"

#   db_subnet_group_name     = "my-rds-subnet-group"
#   db_parameter_group_name  = "my-rds-parameter-group"
#   db_parameter_group_family = "mysql8.0"

#   db_subnet_ids = [module.vpc.subnet_ids["db-subnet-a"], module.vpc.subnet_ids["db-subnet-b"]]

#   db_parameters = [
#     { name = "max_connections", value = "200" },
#     { name = "innodb_buffer_pool_size", value = "536870912" }
#   ]
# }

################################################################################################################################################
#                                                                 ECR                                                                          #
################################################################################################################################################

# module "ecr" {
#   source              = "./modules/ECR"
#   repository_name     = "my-app-repo"
#   image_tag_mutability = "IMMUTABLE"
#   encryption_type      = "AES256"
#   scan_on_push         = true
# }