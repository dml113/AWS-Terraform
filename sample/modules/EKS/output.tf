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