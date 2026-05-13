variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "gitops-eks-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (2 AZs)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (2 AZs)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "public_node_instance_type" {
  description = "EC2 instance type for the public managed node group."
  type        = string
  default     = "t3.small"
}

variable "public_node_desired_size" {
  description = "Desired node count for the public node group."
  type        = number
  default     = 1
}

variable "public_node_min_size" {
  description = "Minimum node count for the public node group."
  type        = number
  default     = 1
}

variable "public_node_max_size" {
  description = "Maximum node count for the public node group."
  type        = number
  default     = 2
}

variable "private_node_instance_type" {
  description = "EC2 instance type for the private managed node group."
  type        = string
  default     = "t3.small"
}

variable "private_node_desired_size" {
  description = "Desired node count for the private node group."
  type        = number
  default     = 1
}

variable "private_node_min_size" {
  description = "Minimum node count for the private node group."
  type        = number
  default     = 1
}

variable "private_node_max_size" {
  description = "Maximum node count for the private node group."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default     = {}
}
