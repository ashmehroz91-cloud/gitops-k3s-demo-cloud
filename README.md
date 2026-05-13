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

1) Configure AWS credentials locally: Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. Get these from AWS after creating an IAM user.

```bash
aws configure
```

After configuration, verify it works:

```bash
aws configure list
```

2) Provision EKS infrastructure with Terraform:

Run from the `terraform/` directory:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates: VPC, subnets (public/private), EKS cluster, node groups, and IAM roles for the ALB controller.

3) Configure kubeconfig for the new cluster:

```bash
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=gitops-eks-demo
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
```

Verify kubeconfig works:

```bash
kubectl cluster-info
```

4) Install AWS Load Balancer Controller:

Run from the repository root:

```bash
chmod +x scripts/install-alb-controller.sh
./scripts/install-alb-controller.sh
```

This script:
- Adds the AWS Helm repository
- Creates a Kubernetes ServiceAccount with IAM role annotation (IRSA)
- Installs the ALB controller chart
- Verifies the installation

5) Install Argo CD (if not present):

Do this only after the AWS Load Balancer Controller is installed and healthy.

```bash
kubectl create namespace argocd
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

If you hit a webhook error, stop here and verify the controller first:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get endpoints -n kube-system aws-load-balancer-webhook-service
```

Recommended order:

1. Install the AWS Load Balancer Controller.
2. Confirm it is running with the command above.
3. Install Argo CD.
4. Apply the Argo CD application.

6) Apply the Argo CD Application:

Run from the repository root:

```bash
kubectl apply -f argocd/applications/gitops-demo.yaml
```

7) Image builds are automatic via GitHub Actions on `main` (`.github/workflows/build-and-push.yml`).

8) Verify cluster and Argo CD:

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl get pods -n default
kubectl get svc -n default
```

9) Open the Argo CD UI and get the initial password:

```bash
PORT=8081
while ss -ltn "sport = :$PORT" | grep -q LISTEN; do
	PORT=$((PORT + 1))
done
kubectl port-forward svc/argocd-server -n argocd "$PORT:443"
```

Then open `https://localhost:$PORT` in a browser.

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

Accessing the app
-----------------


The frontend is exposed through an Ingress (`k8s/frontend-ingress.yaml`) and will be reachable via the ALB DNS name once the AWS Load Balancer Controller provisions an ALB.

Get the ingress hostname (run on your workstation with kubeconfig set):

```bash
kubectl get ingress frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo
```

Then open `http://<alb-hostname>` in a browser.

The backend is internal (`ClusterIP`) and is not accessible from the internet.

Architecture summary
--------------------

- Frontend service: `ClusterIP`, exposed by ALB Ingress
- Backend service: `ClusterIP`, internal only
- Public node group: frontend workload
- Private node group: backend workload (tainted/isolated)

Validation commands
-------------------

```bash
# Confirm services are internal
kubectl get svc frontend backend

# Confirm ingress is provisioned
kubectl get ingress frontend

# Confirm workload placement labels
kubectl get nodes --show-labels | grep workload

# Confirm pod scheduling
kubectl get pods -o wide
```

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

