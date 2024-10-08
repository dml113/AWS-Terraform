
# EKS
locals {
  EKS = {
    cluster_name = "eks-cluster"
    cluster_version = "1.30"
  }
}

module "EKS" {
  source = "./modules/EKS"

  cluster_name   = local.EKS.cluster_name
  cluster_version = local.EKS.cluster_version
  cluster_endpoint_public_access = true

  vpc_id      = module.VPC.vpc_id

  access_entries = {
    root = {
      kubernetes_groups = [""]
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
    }
  }

  subnet_ids  = [
    module.VPC.private_subnet_a_id,
    module.VPC.private_subnet_b_id
  ]
  control_plane_subnet_ids = [
    module.VPC.private_subnet_a_id,
    module.VPC.private_subnet_b_id,
    module.VPC.public_subnet_a_id,
    module.VPC.public_subnet_b_id
  ]
 
  eks_managed_node_groups = {
    app-ng = {
      name            = "app-node"
      name_prefix     = false
      ami_type        = "AL2023_x86_64_STANDARD"
      instance_types  = ["t3.medium"]
      labels          = { app = "nga" }
      desired_size    = 2
      min_size        = 2
      max_size        = 20
      private_networking = true
      volume_type     = "gp2"
      volume_encrypted = true
      iam = {
        with_addon_policies = {
          image_builder = true
          aws_load_balancer_controller = true
          auto_scaler = true
        }
      }
      taints = [
        {
          key    = "app-tier"
          value  = "frontend"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    
    addon-ng = {
      name            = "addon-node"
      name_prefix     = false
      ami_type        = "AL2023_x86_64_STANDARD"
      instance_types  = ["t3.medium"]
      labels          = { role = "addon" }
      desired_size    = 2
      min_size        = 2
      max_size        = 10
      private_networking = true
      volume_type     = "gp2"
      volume_encrypted = true
      iam = {
        with_addon_policies = {
          image_builder = true
          aws_load_balancer_controller = true
          auto_scaler = true
        }
      }
    }
  }

  # Cluster access for admins
  enable_cluster_creator_admin_permissions = true

  # Tags
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}