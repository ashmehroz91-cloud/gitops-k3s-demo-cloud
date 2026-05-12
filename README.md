# EKS GitOps Demo (Terraform + DockerHub + Argo CD)

Purpose
-------

Provision an AWS EKS cluster with Terraform, build images via GitHub Actions, and deploy the app with Argo CD (GitOps). This repo targets a remote EKS cluster.

Deploy-driving files
--------------------

- `terraform/` - EKS infrastructure
- `k8s/` - Kubernetes manifests (source of truth)
- `argocd/applications/gitops-demo.yaml` - Argo CD Application pointing to `k8s/`
- `.github/workflows/build-and-push.yml` - CI that builds and pushes images

Prerequisites
-------------

- AWS account and IAM user with EKS permissions
- Terraform 1.5+
- AWS CLI and `kubectl`

Required GitHub secrets
-----------------------

Store these in GitHub -> Settings -> Secrets -> Actions:
if you have this project into your own repo otherwise you are use ashmehroz1 dockerhub public images

- `DOCKERHUB_TOKEN`
- `DOCKERHUB_USERNAME` 

Quick start (stepwise)
----------------------

1) Configure AWS credentials locally: Set AWs_ACCESS_KEY_ID AND AWS_SECRET_ACCESS_KEY : Get from AWS after creating IAM USER.

```bash
aws configure

After configuration check it with command 

aws configure list 

```

2) Provision EKS with Terraform:

```bash
cd terraform
terraform init
terraform plan 
terraform apply
```

3) Configure kubeconfig for the new cluster. Set `AWS_REGION` before running the command:

```bash
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=gitops-eks-demo
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
```

4) Install Argo CD (if not present):

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

5) Apply the Argo CD Application from this repo:

```bash
kubectl apply -f argocd/applications/gitops-demo.yaml
```

6) Image builds are automatic via GitHub Actions on `main` (`.github/workflows/build-and-push.yml`).

7) Verify cluster and Argo CD:

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl get pods -n default
kubectl get svc -n default
```

8) Open the Argo CD UI and get the initial password:

```bash

PORT=8081
while ss -ltn "sport = :$PORT" | grep -q LISTEN; do
	PORT=$((PORT + 1))
done
kubectl port-forward svc/argocd-server -n argocd "$PORT:443"
# open https://localhost:$PORT

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

Accessing the app
-----------------

The frontend is exposed by `k8s/frontend-service.yaml` as `NodePort:30080`. Find a node IP with `kubectl get nodes -o wide` and open `http://<node-ip>:30080`.

For production use, replace NodePort with a LoadBalancer or Ingress.

Public image setup
------------------

This repo already points to public Docker Hub images under the `ashmehroz1` account, so a collaborator who clones the repo does not need to build or push images just to deploy the app.

For the default setup, keep the image fields in:

- `k8s/backend-deployment.yaml`
- `k8s/frontend-deployment.yaml`
- `.github/workflows/build-and-push.yml`

If you want to use your own images later, replace the `image:` values in the Kubernetes manifests and the image tags in the workflow.

Destroy
-------

```bash
cd terraform
terraform destroy
```

