#!/bin/bash

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error: $error_message"
    exit 1
}

# Step 1: Delete Amazon ECR Repositories
echo "Deleting Amazon ECR Repositories"
# Frontend repository
aws ecr delete-repository --repository-name frontend --force --region us-east-2 &>/dev/null || echo "Frontend ECR repository does not exist."
# Backend repository
aws ecr delete-repository --repository-name backend --force --region us-east-2 &>/dev/null || echo "Backend ECR repository does not exist."

echo "Amazon ECR private repositories deleted successfully."

# Step 2: Delete AWS Load Balancer Controller
echo "Deleting AWS Load Balancer Controller"
helm uninstall aws-load-balancer-controller -n kube-system &>/dev/null || echo "AWS Load Balancer Controller is not installed."

# Step 3: Delete Service Account
echo "Deleting Service Account"
eksctl delete iamserviceaccount --cluster=Three-Tier-K8s-EKS-Cluster --namespace=kube-system --name=aws-load-balancer-controller --region=us-east-2 || handle_error "Failed to delete service account."

# Step 4: Delete OIDC Provider
echo "Deleting OIDC Provider"
eksctl utils disassociate-iam-oidc-provider --region=us-east-2 --cluster=Three-Tier-K8s-EKS-Cluster || handle_error "Failed to disassociate OIDC provider."

# Step 5: Delete IAM policy
echo "Deleting IAM policy"
aws iam delete-policy --policy-arn arn:aws:iam::375728455575:policy/AWSLoadBalancerControllerIAMPolicy || handle_error "Failed to delete IAM policy."

# Step 6: Delete EKS Cluster
echo "Deleting EKS Cluster"
eksctl delete cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-2 --wait || handle_error "Failed to delete EKS cluster."

echo "Script execution completed. All resources have been deleted."
