resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  tags = local.base_tags
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-public-ng"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.public[*].id

  instance_types = [var.public_node_instance_type]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"

  labels = {
    workload = "public"
  }

  scaling_config {
    desired_size = var.public_node_desired_size
    min_size     = var.public_node_min_size
    max_size     = var.public_node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr_read_only
  ]

  tags = local.base_tags
}

resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-private-ng"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = [var.private_node_instance_type]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"

  labels = {
    workload = "private"
  }

  taint {
    key    = "workload"
    value  = "private"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = var.private_node_desired_size
    min_size     = var.private_node_min_size
    max_size     = var.private_node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr_read_only
  ]

  tags = local.base_tags
}
