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
check_status() {
    timeout=1800  # Timeout in seconds (30 minutes)
    start_time=$(date +%s)

    while [ $(( $(date +%s) - $start_time )) -lt $timeout ]; do
        echo "Checking status..."
        last_line=$(tail -n 1 status.txt)
        echo "Last line of status.txt: $last_line"
        grep_result=$(grep "waiting for CloudFormation stack" status.txt)
        if [[ ! -z $grep_result ]]; then
            echo "Waiting for CloudFormation stack..."
            sleep 20
        fi
        ready_result=$(grep "EKS cluster \"Three-Tier-K8s-EKS-Cluster\" in \"us-east-2\" region is ready" status.txt)
        if [[ ! -z $ready_result ]]; then
            echo "EKS cluster is ready"
            rm status.txt
            exit 0
        fi
        error_result=$(grep "\[✖\]" status.txt)
        if [[ ! -z $error_result ]]; then
            echo "Error encountered: $error_result"
            echo "Cluster Creation was not completed due to unexpected Error"
            rm status.txt
            exit 1
        fi
        sleep 5
    done

    echo "Cluster Creation was not completed due to timeout"
    rm status.txt
    exit 1
}

if check_cluster_exists; then
    echo "Moving to Step 3: Update kubeconfig"
    # Move to Step 3
    aws eks update-kubeconfig --region us-east-2 --name Three-Tier-K8s-EKS-Cluster
    echo "Step 3 completed"
else
    create_cluster
    echo "Checking status after EKS cluster creation"
    # Check status
    check_status
fi


# Step 4: Download Load Balancer policy
echo "Download Load Balancer policy"
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json || handle_error "Failed to download Load Balancer policy."

# Step 5: Create IAM policy
echo "Create IAM policy"
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json 2>&1 | grep -q 'EntityAlreadyExists' && echo "Policy AWSLoadBalancerControllerIAMPolicy already exists." || handle_error "Failed to create IAM policy."

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

echo "Script execution completed."
