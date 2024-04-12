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


## Step 2: Create a JumpServer and install Terraform & AWS CLI to deploy our Jenkins Server(EC2) on AWS.
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
