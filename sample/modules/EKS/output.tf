output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_node_group_names" {
  value = [for ng in aws_eks_node_group.this : ng.node_group_name]
}

output "eks_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority
}

output "eks_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "installed_eks_addons" {
  value = [for addon in aws_eks_addon.this : addon.addon_name]
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "eks_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
