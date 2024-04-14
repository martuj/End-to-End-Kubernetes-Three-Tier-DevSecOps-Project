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
Now Install Terraform
```
cd End-to-End-Kubernetes-Three-Tier-DevSecOps-Project && cd TerraformSetup
```
```
chmod +x TerraformSetup.sh
```
```
./Terraform.sh
```

Now will we create the below resources
* s3 bucket
* dynamodb table
* key-pair

For this navigate to the JenkinsServer-Prerequiste
```
cd .. && cd cd JenkinsServer-Prerequiste
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
* Select the Available plugins , Search and select `AWS Credentials` and `Pipeline: AWS Steps` and click on Install. 
* Once, both the plugins are installed, restart your Jenkins service by checking the Restart Jenkins option.
* Login to your Jenkins Server Again

### Task2: Set AWS credentials on Jenkins
* Go to Manage Plugins and click on Credentials
* Click on global.
* Click on `Add Credentials`
* Kind:  `AWS Credentials`
* Scope: Global
* ID: `aws-key`
* Access Key: <Your-access-Key>
* Secret Access key: <Your-secret-access-key> and click on Create.

### Task3: Set GitHub credentials on Jenkins
In Industry Projects your repository will always be private. So, add the username and personal access token of your GitHub account.
* Kind:  `Username with password`
* Scope: Global
* Username: <Your-Github-Username>
* Password: <Your-Github-token>
* ID: github
* Description: github
* Click on Create.

### Task4: Setup EKS Cluster, Load Balancer on our EKS, ECR Private Repositories and ArgoCD
A file called `EKSClusterSetup.sh` is already present at  the current location /home/ubuntu. This file needs to be executed to Setup EKS Cluster, Load Balancer on the EKS, ECR Private Repositories and ArgoCD
```
chmod +x EKSClusterSetup.sh
```
```
./EKSClusterSetup.sh
```





