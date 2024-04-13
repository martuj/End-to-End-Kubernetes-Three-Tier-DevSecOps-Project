# Prerequisites:
Before starting the project, ensure you have the following prerequisites:

* An AWS account with the necessary permissions to create resources.
* Terraform and AWS CLI installed on your local machine.
* Basic familiarity with Kubernetes, Docker, Jenkins, and DevOps principles.

# Setup


## Step 1: Create an IAM user and generate AWS Access and Secret Access key
* Create a new IAM User on AWS and give it to the AdministratorAccess for testing purposes (not recommended for your Organization's Projects)
* Go to the AWS IAM Service and click on Users.
* Click on Create user
* Provide the name to your user and click on Next.
* Select the Attach policies directly option and search for AdministratorAccess then select it.
* Click on the Next.
* Click on Create user
* Now, Select your created user then click on Security credentials and generate access key by clicking on Create access key.
* Select the Command Line Interface (CLI) then select the checkmark for the confirmation and click on Next.
* Provide the Description and click on the Create access key.
* Here, you will see that you got the credentials and also you can download the CSV file for the future.


## Step 2: Create a JumpServer and install Terraform & AWS CLI to deploy Jenkins Server.
### Task-1: Installing Terraform on Ubuntu 20.04 operating system

* Manually Launch a `t2.micro` instance with OS version as `Ubuntu 22.04 LTS`.
* Use tag "`Name : JumpServer`"
* Create a new Keypair with the Name `JumpServer-Keypair`
* In security groups, include ports `22 (SSH)` and `80 (HTTP)`.
* Configure Storage: 8 GiB
* Launch the Instance.
* Once Launched, Connect to the Instance using `MobaXterm` or `Putty` or `EC2 Instance Connect` with username "`ubuntu`".

Once the EC2 is ready, follow the below Commands to perform lab:
```
sudo hostnamectl set-hostname TerraformServer
bash
```
```
sudo apt update
```
```
sudo apt install wget unzip -y
```
```
wget https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip
```
To know the latest Terraform version - [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
```
unzip terraform_1.6.3_linux_amd64.zip
```
```
ls
sudo mv terraform /usr/local/bin
```
```
rm terraform_1.6.3_linux_amd64.zip
```
```
ls
terraform
```
```
terraform -v
```

### Task-2: Install Required Packages. 
```
sudo apt-get install python3-pip -y
```
```
sudo pip3 install awscli
```
```
aws configure
```
* When it prompts for Credentials, Enter the Keys as example shown below
  
| `Access Key ID.` | `Secret Access Key ID.` |
| ------------------ | ------------------------- |
| AKIAIOSFODNN7EXAMPLE | wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY |

##### Note: If Credentials are not available generate from AWS IAM Service
Once LoggedIn check the account access
```
aws s3 ls
```
`Or` Use below command to check whether it is authenticated.
```
aws iam list-users
```

## Step 3: Deploy the Jenkins Server(EC2) using Terraform
Clone the Git repository
```
git clone https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project
```
Now will we create the below resources
* s3 bucket
* dynamodb table
* key-pair

For this navigate to the JenkinsServer-Prerequiste
```
cd End-to-End-Kubernetes-Three-Tier-DevSecOps-Project && cd cd JenkinsServer-Prerequiste
```
```
terraform init
```
```
terraform fmt
```
```
terraform validate
```
```
terraform plan
```
```
terraform apply --auto-approve
```
Once all the `5` resources are craeted navigate to the Jenkins-Server-TF
```
cd .. && cd Jenkins-Server-TF
```
Initialize the backend by running the below command
```
terraform init
```
Run the below command to check the syntax error
```
terraform validate
```
Run the below command to get the blueprint of what kind of AWS services will be created.
```
terraform plan 
```
Now, run the below command to create the infrastructure on AWS Cloud which will take 3 to 4 minutes maximum
```
terraform apply 
```
Now, ssh into the created Jenkins Server(The Public IP of the Jenkins Server is printed on the console) 
```
chmod 400 /home/ubuntu/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/JenkinsServer-Prerequiste/devsecops-key
```
```
ssh -i /home/ubuntu/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/JenkinsServer-Prerequiste/devsecops-key ubuntu@<Public-Ip>
```

## Step 4: Configure the Jenkins
Now, we logged into our Jenkins server.Set the hostname
```
sudo hostnamectl set-hostname JenkinsServer
bash
```
We have installed some services such as Jenkins, Docker, Sonarqube, Terraform, Kubectl, AWS CLI, and Trivy.

Let’s validate whether all our installed or not.
```
jenkins --version
```
```
docker --version
```
```
docker ps
```
```
terraform --version
```
```
kubectl version
```
```
aws --version
```
```
trivy --version
```
```
eksctl --version
```
Now, we have to configure Jenkins. So, copy the public IP of your Jenkins Server and paste it on your favorite browser with an 8080 port.
* Click on `Install suggested plugins`
* The plugins will be installed
* After installing the plugins, continue as `admin`
* Click on `Save and Finish`
* Click on Start using `Jenkins`

## Step 5: Deploy the EKS Cluster.
### Task 1: Configure the AWS.
* Go to Manage Jenkins
* Click on Plugins
* Select the Available plugins , select the given plugins and click on Install. 
** AWS Credentials
** Pipeline: AWS Steps
* Once, both the plugins are installed, restart your Jenkins service by checking the Restart Jenkins option.
* Login to your Jenkins Server Again

### Task2: Set oAWS credentials on Jenkins
* Go to Manage Plugins and click on Credentials
* Click on global.
* Select `AWS Credentials` as Kind and add the ID same as shown in the below snippet except for your AWS Access Key & Secret Access key and click on Create.


The Credentials will look like the below snippet.


Now, We need to add GitHub credentials as well because currently, my repository is Private.

This thing, I am performing this because in Industry Projects your repository will be private.

So, add the username and personal access token of your GitHub account.


Both credentials will look like this.


Create an eks cluster using the below commands.

eksctl create cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-1 --node-type t2.medium --nodes-min 2 --nodes-max 2
aws eks update-kubeconfig --region us-east-1 --name Three-Tier-K8s-EKS-Cluster

Once your cluster is created, you can validate whether your nodes are ready or not by the below command

kubectl get nodes


