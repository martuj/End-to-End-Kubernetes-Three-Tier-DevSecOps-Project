#!/bin/bash

# Function to install jq if not installed
install_jq() {
    if ! command -v jq &>/dev/null; then
        echo "jq is not installed. Installing..."
        sudo apt update
        sudo apt install jq -y
    fi
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error: $error_message"
    exit 1
}

# Step 1: Install jq
install_jq || handle_error "Failed to install jq."

# Step 2: Create EKS Cluster

# Function to handle interrupts and exit gracefully
cleanup() {
    echo "Received interrupt, cleaning up..."
    exit 1
}

# Trap interrupts
trap 'cleanup' INT

# Function to check if the EKS cluster exists
check_cluster_exists() {
    echo "Checking if the EKS cluster exists..."
    if eksctl get cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-2 &> /dev/null; then
        echo "EKS cluster already exists"
        return 0
    else
        echo "EKS cluster does not exist"
        return 1
    fi
}

# Function to create the EKS cluster
create_cluster() {
    echo "Creating EKS cluster..."
    if ! eksctl create cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-2 --node-type t2.medium --nodes-min 2 --nodes-max 2; then
        echo "EKS cluster creation failed, exiting..."
        exit 1
    fi
    echo "EKS cluster creation command completed"
}

# Function to check status
# check_status() {
#     local timeout=1800  # Timeout in seconds (30 minutes)
#     local start_time=$(date +%s)
#     local status_file="status.txt"

#     touch "$status_file" || handle_error "Failed to create status.txt file."

#     while [ $(( $(date +%s) - $start_time )) -lt $timeout ]; do
#         echo "Checking status..."
#         if [ -f "$status_file" ]; then
#             local last_line=$(tail -n 1 "$status_file")
#             echo "Last line of status.txt: $last_line"
#             # Add more detailed status checking logic here
            
#             # Example: Check if the cluster creation completed successfully
#             if grep -q "EKS cluster \"Three-Tier-K8s-EKS-Cluster\" in \"us-east-2\" region is ready" "$status_file"; then
#                 echo "EKS cluster is ready"
#                 rm "$status_file"
#                 exit 0
#             fi

#             # Example: Check if an error occurred
#             if grep -q "\[✖\]" "$status_file"; then
#                 echo "Error encountered during cluster creation. Exiting..."
#                 rm "$status_file"
#                 exit 1
#             fi
#         else
#             break
#         fi
#         sleep 5
#     done

#     echo "Cluster creation did not complete within the timeout period."
#     rm "$status_file"
#     exit 1
# }

if check_cluster_exists; then
    echo "Moving to Step 3: Update kubeconfig"
    break
else
    create_cluster
    # echo "Checking status after EKS cluster creation"
    # # Check status
    # check_status
fi

# Step 3:  Update kubeconfig
echo "Update kubeconfig"
aws eks update-kubeconfig --region us-east-2 --name Three-Tier-K8s-EKS-Cluster

# Step 4: Download Load Balancer policy
echo "Download Load Balancer policy"
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json || handle_error "Failed to download Load Balancer policy."

# Step 5: Create IAM policy
echo "Create IAM policy"
if aws iam get-policy --policy-arn arn:aws:iam::375728455575:policy/AWSLoadBalancerControllerIAMPolicy &>/dev/null; then
    echo "Policy AWSLoadBalancerControllerIAMPolicy already exists."
else
    # Create the policy
    aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json || handle_error "Failed to create IAM policy."
fi

# Step 6: Create OIDC Provider
echo "Create OIDC Provider"
eksctl utils associate-iam-oidc-provider --region=us-east-2 --cluster=Three-Tier-K8s-EKS-Cluster --approve || handle_error "Failed to associate OIDC provider."

# Step 7: Create Service Account
echo "Create Service Account"
# Replace <your_account_id> with your actual account ID
eksctl create iamserviceaccount --cluster=Three-Tier-K8s-EKS-Cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::375728455575:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-east-2 || handle_error "Failed to create service account."

# Step 8: Check if AWS Load Balancer Controller is already installed
echo "Checking if AWS Load Balancer Controller is already installed..."
if kubectl get deployment -n kube-system aws-load-balancer-controller &> /dev/null; then
    echo "AWS Load Balancer Controller is already installed."
else
    # Step 8: Deploy AWS Load Balancer Controller
    echo "Deploy AWS Load Balancer Controller"
    sudo snap install helm --classic || handle_error "Failed to install Helm."
    helm repo add eks https://aws.github.io/eks-charts || handle_error "Failed to add EKS Helm repository."
    helm repo update eks || handle_error "Failed to update Helm repository."
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=my-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller || handle_error "Failed to install AWS Load Balancer Controller: Installation failed or name already in use."
fi

# Step 9: Create Amazon ECR Private Repositories
echo "Create Amazon ECR Private Repositories"
# Frontend repository
aws ecr describe-repositories --repository-names frontend --region us-east-2 &>/dev/null || aws ecr create-repository --repository-name frontend --region us-east-2 || handle_error "Failed to create frontend ECR repository."
# Backend repository
aws ecr describe-repositories --repository-names backend --region us-east-2 &>/dev/null || aws ecr create-repository --repository-name backend --region us-east-2 || handle_error "Failed to create backend ECR repository."

echo "Amazon ECR private repositories created successfully."

# Step 10: Configure ECR Locally
echo "Configuring ECR Locally"
if ! aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 375728455575.dkr.ecr.us-east-2.amazonaws.com; then
    handle_error "Failed to login to ECR."
fi

# Step 11: Create namespaces
echo "Creating namespaces..."
#kubectl create namespace three-tier || handle_error "Failed to
kubectl create namespace three-tier || handle_error "Failed to create namespace."

# Step 12: Deploy the application to the Kubernetes Cluster
echo "Deploying the application to the Kubernetes Cluster..."

# Step 12A: Deploy the frontend
echo "Deploying the frontend..."
kubectl apply -f frontend-deployment.yaml -n three-tier || handle_error "Failed to deploy frontend."

# Step 12B: Deploy the backend
echo "Deploying the backend..."
kubectl apply -f backend-deployment.yaml -n three-tier || handle_error "Failed to deploy backend."

# Step 13: Expose the services
echo "Exposing the services..."
kubectl apply -f frontend-service.yaml -n three-tier || handle_error "Failed to expose frontend service."
kubectl apply -f backend-service.yaml -n three-tier || handle_error "Failed to expose backend service."

# Step 14: Check deployment status
echo "Checking deployment status..."
kubectl get deployments -n three-tier
kubectl get services -n three-tier

# Step 15: Set ArgoCD server hostname and admin password
echo "Setting ArgoCD server hostname and admin password..."

# Function to set ArgoCD server hostname
set_argocd_server() {
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
    if [ -z "$ARGOCD_SERVER" ]; then
        handle_error "Failed to retrieve ArgoCD server hostname."
    fi
}

# Function to set ArgoCD admin password
set_argocd_password() {
    ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    if [ -z "$ARGO_PWD" ]; then
        handle_error "Failed to retrieve ArgoCD admin password."
    fi
}

# Set ArgoCD server hostname
set_argocd_server

# Set ArgoCD admin password
set_argocd_password

echo "ArgoCD server hostname: $ARGOCD_SERVER"
echo "ArgoCD admin password: $ARGO_PWD"

# End of script
echo "Script execution completed."

