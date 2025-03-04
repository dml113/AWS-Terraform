################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################

module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"

    name            = "my-vpc"
    cidr            = "10.0.0.0/16"
    azs             = ["ap-northeast-2a", "ap-northeast-2b"]

    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnet_names = ["my-public-subnet-a" , "my-public-subnet-b"]
    map_public_ip_on_launch = true
    public_subnet_tags = {
      "kubernetes.io/role/elb" = 1
    }

    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    private_subnet_names = ["my-private-subnet-a" , "my-private-subnet-b"]
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = 1,
      "karpenter.sh/discovery"          = "my-eks-cluster"
    }

    # database_subnets = ["10.0.5.0/24", "10.0.6.0/24"]
    # database_subnet_names = ["my-db-subnet-a", "my-db-subnet-b"]

    # create_database_subnet_group = true
    # create_database_subnet_route_table = true

    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}

################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  key_pair_name          = "bastion-key"
  iam_role_name          = "BastionAdminRole"
  vpc_id                 = module.vpc.vpc_id
  user_data              = filebase64("${path.module}/user_data/user_data.sh")
}

################################################################################################################################################
#                                                                 EKS                                                                          #
################################################################################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.32"

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  cluster_security_group_additional_rules = {
    hybrid-all = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }


  enable_cluster_creator_admin_permissions = true

  access_entries = {
  # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = module.ec2.bastion_role_arn

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  # Optional
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [ module.vpc.private_subnets[0], module.vpc.private_subnets[1] ]
  control_plane_subnet_ids = [ module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.private_subnets[0], module.vpc.private_subnets[1] ]

  eks_managed_node_groups = {
    app-ng = {
      use_name_prefix   = false
      name              = "app-ng"

      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.small"]
      labels          = { app = "nga"}

      desired_size = 2
      min_size     = 2
      max_size     = 10

      iam = {
        with_addon_policies = {
          image_builder = true
          aws_load_balancer_controller = true
          auto_scaler = true
        }
      }
      create_launch_template = true
      launch_template_name   = "app-node-lt"
      launch_template_tags = {
        Name = "app-node"
      }
    }
  }
  tags = {
    "karpenter.sh/discovery" = "my-eks-cluster"
  }
}

################################################################################################################################################
#                                                                 RDS                                                                          #
################################################################################################################################################

# module "rds_sg" {
#   source = "terraform-aws-modules/security-group/aws"

#   name        = "my-rds-sg"
#   description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks      = [ module.vpc.vpc_cidr_block ]
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 3306
#       to_port     = 3306
#       protocol    = "tcp"
#       description = "MySQL"
#       cidr_blocks = module.vpc.vpc_cidr_block
#     }
#   ]
# }

# module "db" {
#   source = "terraform-aws-modules/rds/aws"

#   identifier = "my-db"

#   engine            = "mysql"
#   engine_version    = "8.0"
#   instance_class    = "db.t3.medium"
#   allocated_storage = 20

#   db_name  = "daydb"
#   username = "root"
#   port     = "3306"

#   iam_database_authentication_enabled = true

#   vpc_security_group_ids = [module.rds_sg.security_group_id]

#   monitoring_interval    = "30"
#   monitoring_role_name   = "MyRDSMonitoringRole"
#   create_monitoring_role = true

#   tags = {
#     Owner       = "admin"
#     Environment = "dev"
#   }

#   # DB subnet group
#   create_db_subnet_group = true
#   subnet_ids             = module.vpc.database_subnets

#   # DB parameter group
#   family = "mysql8.0"

#   # DB option group
#   major_engine_version = "8.0"

#   # Database Deletion Protection
#   deletion_protection = false

#   parameters = [
#     {
#       name  = "character_set_client"
#       value = "utf8mb4"
#     },
#     {
#       name  = "character_set_server"
#       value = "utf8mb4"
#     }
#   ]

#   options = [
#     {
#       option_name = "MARIADB_AUDIT_PLUGIN"

#       option_settings = [
#         {
#           name  = "SERVER_AUDIT_EVENTS"
#           value = "CONNECT"
#         },
#         {
#           name  = "SERVER_AUDIT_FILE_ROTATIONS"
#           value = "37"
#         },
#       ]
#     },
#   ]
# }