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
    if eksctl get cluster --name Three-Tier-K8s-EKS-Cluster --region us-west-1 &> /dev/null; then
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
    if ! eksctl create cluster --name Three-Tier-K8s-EKS-Cluster --region us-west-1 --node-type t2.medium --nodes-min 2 --nodes-max 2; then
        echo "EKS cluster creation failed, exiting..."
        exit 1
    fi
    echo "EKS cluster creation command completed"
}

if check_cluster_exists; then
    echo "Moving to Step 3: Update kubeconfig"
    # Move to Step 3
    aws eks update-kubeconfig --region us-west-1 --name Three-Tier-K8s-EKS-Cluster
    echo "Step 3 completed"
else
    create_cluster
    echo "Checking status after EKS cluster creation"
fi

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
eksctl utils associate-iam-oidc-provider --region=us-west-1 --cluster=Three-Tier-K8s-EKS-Cluster --approve || handle_error "Failed to associate OIDC provider."

# Step 7: Create Service Account
echo "Create Service Account"
# Replace <your_account_id> with your actual account ID
eksctl create iamserviceaccount --cluster=Three-Tier-K8s-EKS-Cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::375728455575:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-west-1 || handle_error "Failed to create service account."

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
aws ecr describe-repositories --repository-names frontend --region us-west-1 &>/dev/null || aws ecr create-repository --repository-name frontend --region us-west-1 || handle_error "Failed to create frontend ECR repository."
# Backend repository
aws ecr describe-repositories --repository-names backend --region us-west-1 &>/dev/null || aws ecr create-repository --repository-name backend --region us-west-1 || handle_error "Failed to create backend ECR repository."

echo "Amazon ECR private repositories created successfully."

# Step 10: Configure ECR Locally
echo "Configuring ECR Locally"
if ! aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 375728455575.dkr.ecr.us-west-1.amazonaws.com; then
    handle_error "Failed to login to ECR."
fi

# Step 11: Create namespaces
echo "Creating namespaces..."
if kubectl get namespace three-tier &> /dev/null; then
    echo "Namespace three-tier already exists."
else
    kubectl create namespace three-tier || handle_error "Failed to create namespace three-tier."
fi

if kubectl get namespace argocd &> /dev/null; then
    echo "Namespace argocd already exists."
else
    kubectl create namespace argocd || handle_error "Failed to create namespace argocd."
fi

# Step 12: Create ECR secret
echo "Creating ECR secret..."
if kubectl get secret ecr-registry-secret -n three-tier &> /dev/null; then
    echo "Secret ecr-registry-secret already exists."
else
    kubectl create secret generic ecr-registry-secret \
      --from-file=.dockerconfigjson=${HOME}/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson --namespace three-tier || handle_error "Failed to create ECR secret."
fi

# Step 13: Deploy ArgoCD
echo "Deploying ArgoCD..."
if kubectl get svc -n kube-system aws-load-balancer-webhook-service &> /dev/null; then
    echo "AWS Load Balancer webhook service exists. Proceeding with ArgoCD deployment..."
    if kubectl get deployment -n argocd argocd-server &> /dev/null; then
        echo "ArgoCD is already installed."
    else
        # Wait for the service to become available
        echo "Waiting for AWS Load Balancer webhook service to become available..."
        kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system || handle_error "Timed out waiting for AWS Load Balancer webhook service to become available."
        
        # Deploy ArgoCD
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml || handle_error "Failed to deploy ArgoCD: Could not reach webhook service."
    fi
else
    echo "AWS Load Balancer webhook service does not exist. ArgoCD deployment cannot proceed."
    handle_error "AWS Load Balancer webhook service does not exist."
fi



# Step 14: Patch ArgoCD service
echo "Patching ArgoCD service..."
if kubectl get deployment -n argocd argocd-server &> /dev/null; then
    echo "ArgoCD server deployment found. Proceeding with patching..."
    # Wait for the service to be created
    sleep 10
    # Check for the existence of the service
    if kubectl get svc -n argocd argocd-server &> /dev/null; then
        echo "ArgoCD server service found."
        # Patch the service
        kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' || handle_error "Failed to patch ArgoCD service."
        echo "ArgoCD Patch Update Successful."
    else
        echo "ArgoCD server service not found. Service might not have been created yet."
    fi
else
    echo "ArgoCD server deployment not found. Skipping service patching."
fi


echo "ArgoCD Patch Update Successful."

# Function to get ArgoCD server hostname
get_argocd_hostname() {
    kubectl get svc argocd-server -n argocd -o json | jq -r '.status.loadBalancer.ingress[0].hostname'
}

# Function to get ArgoCD initial admin password
get_argocd_password() {
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
}

# Function to get ArgoCD server hostname
get_argocd_hostname() {
    local timeout=300  # Timeout in seconds (5 minutes)
    local start_time=$(date +%s)

    while [ $(( $(date +%s) - $start_time )) -lt $timeout ]; do
        local hostname=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null)
        if [ -n "$hostname" ]; then
            echo "$hostname"
            return 0
        fi
        sleep 10
    done
    echo "Timed out waiting for ArgoCD server service to become available."
    return 1
}

# Export ArgoCD server hostname and password
export ARGOCD_SERVER=$(get_argocd_hostname)
export ARGO_PWD=$(get_argocd_password)

# Step 15: Installing Helm
# Function to add Helm repositories
add_helm_repositories() {
    local repo_name="$1"
    local repo_url="$2"
    if ! helm repo list | grep -q "$repo_name"; then
        helm repo add "$repo_name" "$repo_url" || handle_error "Failed to add Helm repository: $repo_name."
    else
        echo "Helm repository $repo_name already exists. Skipping..."
    fi
}

# Function to install Helm chart
install_helm_chart() {
    local chart_name="$1"
    local chart_repo="$2"
    local release_name="$3"
    if ! helm list -A | grep -q "$release_name"; then
        helm install "$release_name" "$chart_repo/$chart_name" || handle_error "Failed to install Helm chart: $chart_name."
    else
        echo "Helm chart $chart_name already installed with release name $release_name. Skipping..."
    fi
}

# Add Helm repositories
echo "Installing Helm, promethus and Grafana"
add_helm_repositories "stable" "https://charts.helm.sh/stable"
add_helm_repositories "prometheus-community" "https://prometheus-community.github.io/helm-charts"

# Install Prometheus stack
install_helm_chart "kube-prometheus-stack" "prometheus-community" "my-kube-prometheus-stack"

# Step 16: Print ArgoCD Server, UserID and PWD
# Print ArgoCD password
echo "ArgoCD Server: $ARGOCD_SERVER"
echo "ArgoCD UserName: admin"
echo "ArgoCD Password: $ARGO_PWD"

# You can now use $ARGOCD_SERVER and $ARGO_PWD variables in your script as needed
echo "Script Execution Completed!"
