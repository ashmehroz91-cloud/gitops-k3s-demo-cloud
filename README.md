# EKS GitOps Demo (Terraform + DockerHub)

This repository provisions a minimal AWS EKS cluster with Terraform and deploys the backend/frontend app using DockerHub images. It is designed for a low-cost setup using a single small node and NodePort service.

## Repository layout

- `backend/` - Node/Express backend
- `frontend/` - Next.js frontend
- `k8s/` - Kubernetes manifests for EKS
- `terraform/` - EKS infrastructure (VPC + cluster + node group)
- `.github/workflows/` - CI/CD pipelines

## Prerequisites

- AWS account and IAM user with EKS/VPC/IAM permissions
- Terraform 1.5+
- AWS CLI
- DockerHub account

## GitHub secrets

Set these repository secrets for the workflows:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (example: `us-east-1`)
- `EKS_CLUSTER_NAME` (example: `gitops-eks-demo`)
- `DOCKERHUB_TOKEN`

## Terraform: create the EKS cluster

```bash
cd terraform
terraform init
terraform plan 
terraform apply
```

Terraform creates:
- VPC with two public subnets
- EKS control plane
- Managed node group (1 x t3.micro)

## Build and push images

Images are built and pushed by the GitHub Actions workflow on `main`:

- `.github/workflows/build-and-push.yml`

Tags pushed:
- `ashmehroz1/gitops-demo-backend:latest`
- `ashmehroz1/gitops-demo-frontend:latest`
- `ashmehroz1/gitops-demo-backend:<git-sha>`
- `ashmehroz1/gitops-demo-frontend:<git-sha>`

## Deploy to EKS (GitHub Actions)

Run the workflow:

- `Deploy to EKS` with `image_tag=latest` (or a specific git SHA tag)

The workflow applies `k8s/` and updates images using DockerHub tags.

## Access the app (NodePort)

The frontend service is exposed as NodePort `30080`. Get the node public IP and open:

```
http://<node-public-ip>:30080
```

You can find the node IP with:

```bash
kubectl get nodes -o wide
```

## Update image names

If your DockerHub username differs, update the image fields in:

- `k8s/backend-deployment.yaml`
- `k8s/frontend-deployment.yaml`

## Destroy

```bash
cd terraform
terraform destroy
```

## Cost note (free tier)

The node group uses a single `t3.micro`, which is eligible for AWS free tier. EKS control plane itself is not free. Consider deleting the cluster when not in use.
