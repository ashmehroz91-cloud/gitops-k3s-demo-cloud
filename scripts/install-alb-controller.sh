#!/bin/bash
# Install AWS Load Balancer Controller on EKS cluster.
# Run this after Terraform has created the cluster and kubeconfig is configured.

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="${EKS_CLUSTER_NAME:-gitops-eks-demo}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NAMESPACE="kube-system"
RELEASE_NAME="aws-load-balancer-controller"
CHART_REPO="eks"
CHART_URL="https://aws.github.io/eks-charts"
ROLE_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/${CLUSTER_NAME}-alb-controller-role"
VPC_ID="$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${CLUSTER_NAME}-vpc" --query "Vpcs[0].VpcId" --output text)"

log() {
  echo -e "${YELLOW}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

fail() {
  echo -e "${RED}$1${NC}"
}

cleanup_stuck_release() {
  local status_output
  status_output=$(helm status "${RELEASE_NAME}" -n "${NAMESPACE}" 2>/dev/null || true)

  if echo "${status_output}" | grep -qiE 'pending-install|pending-upgrade|pending-rollback'; then
    log "Found a stuck Helm release state. Removing Helm release secrets and retrying..."
    kubectl delete secret -n "${NAMESPACE}" -l owner=helm,name="${RELEASE_NAME}" --ignore-not-found=true || true
  fi
}

install_controller() {
  helm upgrade --install "${RELEASE_NAME}" "${CHART_REPO}/aws-load-balancer-controller" \
    -n "${NAMESPACE}" \
    --set clusterName="${CLUSTER_NAME}" \
    --set vpcId="${VPC_ID}" \
    --set serviceAccount.create=false \
    --set serviceAccount.name="${RELEASE_NAME}" \
    --set region="${AWS_REGION}" 2> /tmp/alb-controller-helm.err
}

if ! command -v kubectl >/dev/null 2>&1; then
  fail "Error: kubectl is not installed"
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  fail "Error: helm is not installed"
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  fail "Error: kubectl cannot connect to the cluster. Configure kubeconfig first."
  exit 1
fi

log "Installing AWS Load Balancer Controller..."
log "Cluster: ${CLUSTER_NAME}"
log "Region: ${AWS_REGION}"
log "VPC ID: ${VPC_ID}"

log "Adding Helm repository..."
helm repo add "${CHART_REPO}" "${CHART_URL}" >/dev/null
helm repo update >/dev/null

log "Ensuring kube-system namespace exists..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

log "Creating ServiceAccount with IRSA..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${RELEASE_NAME}
  namespace: ${NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: ${ROLE_ARN}
EOF

success "ServiceAccount created"

log "Installing AWS Load Balancer Controller Helm chart..."
if ! install_controller; then
  if grep -Fq "another operation (install/upgrade/rollback) is in progress" /tmp/alb-controller-helm.err 2>/dev/null; then
    cleanup_stuck_release
    log "Retrying install after cleanup..."
    install_controller
  else
    fail "Helm install failed. Re-run the script after checking cluster status."
    exit 1
  fi
fi

success "AWS Load Balancer Controller install command completed"

log "Quick status check (non-blocking)..."
helm status "${RELEASE_NAME}" -n "${NAMESPACE}" || true
kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=aws-load-balancer-controller || true

success "Done!"
echo
echo "Next steps:"
echo "  1. Apply Argo CD: kubectl apply -f argocd/applications/gitops-demo.yaml"
echo "  2. Check ingress status: kubectl get ingress"
echo "  3. Get ALB hostname: kubectl get ingress frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
