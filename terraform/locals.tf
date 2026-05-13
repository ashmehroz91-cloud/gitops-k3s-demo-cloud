locals {
  base_tags = merge(
    {
      Project = "gitops-eks-demo"
    },
    var.tags
  )
}
