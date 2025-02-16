variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_addons" {
  description = "List of EKS addons to enable"
  type        = list(string)
  default     = ["kube-proxy", "vpc-cni", "coredns"]
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "vpc_subnets" {
  description = "Map of VPC subnet IDs"
  type = object({
    public  = list(string)
    private = list(string)
  })

  # Ensure at least one of public or private is non-empty
  validation {
    condition     = length(var.vpc_subnets.public) > 0 || length(var.vpc_subnets.private) > 0
    error_message = "You must provide at least one public or private subnet."
  }
}

variable "cluster_public_access" {
  description = "Enable or disable public access to the EKS cluster"
  type        = bool
  default     = true # 기본값을 true로 설정 (Public Access 허용)
}

variable "cluster_private_access" {
  description = "Enable or disable private access to the EKS cluster"
  type        = bool
  default     = true # 기본값을 true로 설정 (Private Access 허용)
}

variable "managed_node_groups" {
  description = "List of node group configurations"
  type = list(object({
    node_name         = string
    nodegroup_name    = string
    instance_type     = string
    desired_capacity  = number
    min_size          = number
    max_size          = number
    ami_family        = string
    private_networking = bool
    volume_type       = string
    volume_encrypted  = bool
    iam_policies      = object({
      image_builder             = bool
      aws_load_balancer_controller = bool
      auto_scaler              = bool
    })
  }))
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "allowed_cidrs" {
  description = "allowed cidrs"
  type        = list
}