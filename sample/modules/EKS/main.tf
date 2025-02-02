locals {
  subnet_ids = flatten(concat(var.vpc_subnets.public, var.vpc_subnets.private))
}

# EKS 클러스터용 Security Group 생성
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "eks-cluster-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# NodeGroup용 Security Group 생성
resource "aws_security_group" "eks_nodegroup_sg" {
  name_prefix = "eks-nodegroup-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodegroup-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

  vpc_config {
    subnet_ids             = local.subnet_ids
    security_group_ids     = [aws_security_group.eks_cluster_sg.id]  # 클러스터 SG 적용
    endpoint_public_access  = var.cluster_public_access
    endpoint_private_access = var.cluster_private_access
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_launch_template" "eks_nodes" {
  for_each = { for ng in var.managed_node_groups : ng.nodegroup_name => ng }

  name_prefix   = "eks-${each.value.nodegroup_name}-lt"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = each.value.node_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  for_each = { for ng in var.managed_node_groups : ng.nodegroup_name => ng }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.nodegroup_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = flatten([for subnet_id in var.vpc_subnets.private : subnet_id])
  instance_types  = [each.value.instance_type]
  ami_type        = each.value.ami_family

  launch_template {
    id      = aws_launch_template.eks_nodes[each.key].id
    version = "$Latest"
  }

  scaling_config {
    desired_size = each.value.desired_capacity
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  depends_on = [aws_eks_cluster.this]
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ])
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = each.value
}
