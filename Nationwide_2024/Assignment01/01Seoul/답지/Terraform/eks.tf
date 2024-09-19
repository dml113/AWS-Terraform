#module "eks" {
#  source = "terraform-aws-modules/eks/aws"
#
#  cluster_name                    = "wsi-eks-cluster"
#  cluster_version                 = "1.29"
#  cluster_endpoint_private_access = true
#  cluster_endpoint_public_access  = false
#  cluster_security_group_additional_rules = {
#    egress_nodes_ephemeral_ports_tcp = {
#      description                = "To node 1025-65535"
#      protocol                   = "tcp"
#      from_port                  = 1025
#      to_port                    = 65535
#      type                       = "egress"
#      source_node_security_group = true
#    },
#    ingress_bastion_host_tcp = {
#      description                = "From bastion host"
#      protocol                   = "tcp"
#      from_port                  = 0
#      to_port                    = 65535
#      type                       = "ingress"
#      source_security_group_id = aws_security_group.wsi_bastion_sg.id
#    }
#  }
#
#  # # Extend node-to-node security group rules
#  # node_security_group_additional_rules = {
#  #   ingress_self_all = {
#  #     description = "Node to node all ports/protocols"
#  #     protocol    = "-1"
#  #     from_port   = 0
#  #     to_port     = 0
#  #     type        = "ingress"
#  #     self        = true
#  #   }
#  #   egress_all = {
#  #     description      = "Node all egress"
#  #     protocol         = "-1"
#  #     from_port        = 0
#  #     to_port          = 0
#  #     type             = "egress"
#  #     cidr_blocks      = ["0.0.0.0/0"]
#  #     ipv6_cidr_blocks = ["::/0"]
#  #   }
#  # }
#
#  eks_managed_node_groups  = {
#    wsi-addon-nodegroup = {
#      name                 = "wsi-addon-nodegroup"
#      use_name_prefix = false
#      instance_types       = ["t4g.large"]
#      ami_type               = "BOTTLEROCKET_ARM_64" // Bottlerocket AMI
#      platform = "bottlerocket"
#      subnet_ids = [aws_subnet.wsi_app_a.id, aws_subnet.wsi_app_b.id]
#      labels = {
#        "role" = "addon"
#      }
#      tags = {
#        "kubernetes.io/cluster/wsi-app-nodegroup" = "owned"
#      }
#      desired_size         = 2
#      min_size             = 2
#      max_size = 20
#    }
#    wsi-app-nodegroup = {
#      name                 = "wsi-app-node-nodegroup"
#      use_name_prefix = false
#      instance_types       = ["m5.xlarge"]
#      ami_type = "BOTTLEROCKET_x86_64"
#      platform = "bottlerocket"
#
#      imds_support         = "v2"
#      imds_http_tokens      = "required"
#      imds_http_put_response_hop_limit = 1
#      subnet_ids = [aws_subnet.wsi_app_a.id, aws_subnet.wsi_app_b.id]
#      labels = {
#        "role" = "app"
#      }
#      tags = {
#        "kubernetes.io/cluster/wsi-app-nodegroup" = "owned"
#      }
#      desired_size         = 2
#      min_size             = 2
#      max_size = 20
#    }
#  }
#  fargate_profiles = {
#    wsi-app-fargate = {
#      name = "wsi-app-fargate"
#      selectors = [
#        {
#          namespace = "wsi"
#          labels = {
#            "app" = "order"
#          }
#        }
#      ]
#    }
#  }
#
#  vpc_id     = aws_vpc.wsi_vpc.id
#  subnet_ids = [aws_subnet.wsi_app_a.id, aws_subnet.wsi_app_b.id]
#
#  cloudwatch_log_group_retention_in_days = 7
#
#  cluster_enabled_log_types = [
#    "api",
#    "audit",
#    "authenticator",
#    "controllerManager",
#    "scheduler"
#  ]
#
#  access_entries = {
#    admin = {
#      kubernetes_groups = []
#      principal_arn = aws_iam_role.wsi_bastion_role.arn
#
#      policy_associations = {
#        myeks = {
#          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#          access_scope = {
#            namespaces = []
#            type = "cluster"
#          }
#        }
#      }
#    }
#  }
#}
#