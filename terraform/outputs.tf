output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name."
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster API endpoint."
}

output "kubeconfig_command" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}"
  description = "Command to configure local kubeconfig."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs."
}

output "public_node_group_name" {
  value       = aws_eks_node_group.public.node_group_name
  description = "Public node group name."
}

output "private_node_group_name" {
  value       = aws_eks_node_group.private.node_group_name
  description = "Private node group name."
}
