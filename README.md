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

Installing Terraform on Ubuntu 20.04 operating system
* Manually Launch a `t2.micro` instance with OS version as `Ubuntu 22.04 LTS`.
* Use tag "`Name : JumpServer`"
* Create a new Keypair with the Name `JumpServer-Keypair`
* In security groups, include ports `22 (SSH)` and `80 (HTTP)`.
* Configure Storage: 8 GiB
* Launch the Instance.
* Once Launched, Connect to the Instance using `MobaXterm` or `Putty` or `EC2 Instance Connect` with username "`ubuntu`".

Once the EC2 is ready, follow the below Commands to perform lab:

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
./TerraformSetup.sh
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
Now will we create the below resources
* s3 bucket
* dynamodb table
* key-pair

For this navigate to the JenkinsServer-Prerequiste
```
cd ..  && cd JenkinsServer-Prerequiste
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
eksctl version
```
If the above tools are not installed, create a file and paste the installation script from `Jenkins-Server-TF/tools-install.sh` and execute

Now, configure the AWS.
```
aws configure
```
Execute the below command to retrieve the Jenkins password
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Save the above password for future use
Now, we have to configure Jenkins. So, copy the public IP of your Jenkins Server and paste it on your favorite browser with an 8080 port.
* Click on `Install suggested plugins`
* The plugins will be installed
* After installing the plugins, continue as `admin`
* Click on `Save and Finish`
* Click on Start using `Jenkins`
* UserId : `admin`
* Password : `The password retrieved above`

## Step 5: Deploy the EKS Cluster.
### Configure the AWS.
* Go to Manage Jenkins
* Click on Plugins
* Select the Available plugins , Search and select `AWS Credentials` and `Pipeline: AWS Steps` and click on Install. 
* Once, both the plugins are installed, restart your Jenkins service by checking the Restart Jenkins option.
* Login to your Jenkins Server Again

### Set AWS credentials on Jenkins
* Go to Manage Plugins and click on Credentials
* Click on global.
* Click on `Add Credentials`
* Kind:  `AWS Credentials`
* Scope: Global
* ID: `aws-key`
* Access Key: (Your-access-Key)
* Secret Access key: (Your-secret-access-key)
* Click on Create.

### Set GitHub credentials on Jenkins
In Industry Projects your repository will always be private. So, add the username and personal access token of your GitHub account.
* Kind:  `Username with password`
* Scope: `Global`
* Username: <Your-Github-Username>
* Password: <Your-Github-token>
* ID: `GITHUB`
* Description: `GITHUB`
* Click on Create.

### Setup EKS Cluster, Load Balancer on our EKS, ECR Private Repositories and ArgoCD

Go back to the Jenkins CLI.

A file called `EKSClusterSetup.sh` is already present at  the current location /home/ubuntu. This file needs to be executed to Setup EKS Cluster, Load Balancer on the EKS, ECR Private Repositories and ArgoCD
```
chmod +x EKSClusterSetup.sh
```
```
./EKSClusterSetup.sh
```

## Step 6:  Configure ArgoCD
* To access the argoCD, copy the LoadBalancer DNS and hit on your favorite browser.
* You will get a warning.
* Click on Advanced.
* Click on the link which is appearing under Hide advanced
* Enter the username and password printed on the console in argoCD and click on SIGN IN.

## Step 7: Configure Sonarqube for our DevSecOps Pipeline
* Copy your Jenkins Server public IP and paste it on your browser with a 9000 port.
* The username and password will be admin
* Click on Log In.
* Update the password
* Click on `Administration then Security`, and select `Users`
* Click on `Update tokens` and give the token name as `sonar-token`
* Click on `Generate`
* Copy the token keep it somewhere safe and click on `Done`.

Now, we have to configure webhooks for quality checks.
* Click on `Administration` then, `Configuration` and select `Webhooks`
* Click on `Create`
* Provide the name of your project as `jenkins` and in the URL, provide the Jenkins server public IP with port 8080 add sonarqube-webhook in the suffix, and click on Create. (`http://<jenkins-server-public-ip>:8080/sonarqube-webhook/`)
* Here, you can see the webhook.

Now, we have to create a Project for frontend code.
* Click on `Project`.
* Click on `Manually`.
* Provide the display name `three-tier-frontend` to your Project and click on Setup
* Click on Locally.
* Select the Use existing token and paste the `sonar-token` that you copied and click on Continue.
* Select `Other` and `Linux` as OS.

Now, we have to create a Project for backend code.
* Click on `Project`.
* Click on `Create-Project`
* Click on `Manually`.
* Provide the display name `three-tier-backend` to your Project and click on Setup
* Click on Locally.
* Select the Use existing token and paste the `sonar-token` that you copied and click on Continue.
* Select `Other` and `Linux` as OS.

## Step 8: Storing the Sonar Credentials on Jenkins 
Now, we have to store the sonar credentials.
* Go to Dashboard -> Manage Jenkins -> Credentials
* Select the kind as `Secret text` paste your `sonar-token` in Secret.
* Add `sonar-token` in  `ID` and `Description`.
* Click on Create

Add Github Credentilas
* Kind:  `Secret Text`
* Scope: `Global`
* Secret: (Your-Github-token)
* ID: `github`
* Description: `github`
* Click on Create.

  
## Step 9: Storing the ECR Credentials on Jenkins 

Now, according to our Pipeline, we need to add an Account ID in the Jenkins credentials because of the ECR repo URI.
* Select the kind as `Secret text` and paste your `AWS Account ID` in Secret.
* Add `ACCOUNT_ID` in  `ID` and `Description`.
* Click on Create

Now, we need to provide our ECR image name for frontend which is frontend only.
* Select the kind as `Secret text` and paste your `frontend` in Secret.
* Add `ECR_REPO1` in  `ID` and `Description`.
* Click on Create

Now, we need to provide our ECR image name for the backend which is backend only.
* Select the kind as `Secret text` and paste your `backend` in Secret.
* Add `ECR_REPO2` in  `ID` and `Description`.
* Click on Create

## Step 10: Install the required plugins and configure the plugins to deploy our Three-Tier Application
Install the following plugins by going to Dashboard -> Manage Jenkins -> Plugins -> Available Plugins
* Docker
* Docker Commons
* Docker Pipeline
* Docker API
* docker-build-step
* Eclipse Temurin installer
* NodeJS
* OWASP Dependency-Check
* SonarQube Scanner

Now, we have to configure the installed plugins.
* Go to Dashboard -> Manage Jenkins -> Tools

We are configuring jdk
* Search for jdk
* Click on `Add JDK`
* `Name` -> jdk
* `Install automatically` -> Select `Install from adoptium.net` -> Version : `jdk-17.0.1 + 12`

Now, we will configure the sonarqube-scanner
* Search for the sonarqube scanner and provide the configuration like the below.
* Click on `Add SonarQube Scanner`
* Name : `sonar-scanner`
* `Install automatically` -> Select `Install from Maven Central` -> Version : `SonarQube Scanner 5.0.1.3006`
  

Now, we will configure nodejs
* Search for NodeJS and provide the configuration like the below.
* Click on `Add NodeJS`
* Name : `nodejs`
* `Install automatically` -> Select `Install from nodejs.org` -> Version : `NodeJS 14.0.0`

Now, we will configure the OWASP Dependency check
* Search for Dependency-Check and provide the configuration like the below.
* Click on `Add Dependency-Check`
* Name : `DP-Check`
* `Install automatically` -> Select `Install from github.com` -> Version : `dependency-check 9.0.9`

Now, we will configure the docker
* Search for docker and provide the configuration like the below .
* Click on `Add Docker`
* Name : `docker`
* `Install automatically` -> Select `Download from docker.com` -> Version : `latest`

Click on `Save`

Now, we have to set the path for Sonarqube in Jenkins
* Go to Dashboard -> Manage Jenkins -> System

Search for SonarQube installations
* Provide the name as `sonar-server`, then in the Server URL copy the sonarqube public IP (same as Jenkins) with port 9000 (http://(Jenkins-ip>:9000/)select the sonar token that we have added recently, and click on Apply & Save.

Now, we are ready to create our Jenkins Pipeline to deploy our Backend Code.
* Go to Jenkins Dashboard
* Click on New Item
* Provide the name as `Three-Tier-Backend-Application` and select `Pipeline` and click on OK.
* Copy and paste from `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/blob/master/Jenkins-Pipeline-Code/Jenkinsfile-Backend` in the Pipeline Script
* Click Apply & Save.
* Now, click on the build.
* Our pipeline was successful after a few common mistakes.

Note: Do the changes in the Pipeline according to your project.

Now, we are ready to create our Jenkins Pipeline to deploy our Frontend Code.
* Go to Jenkins Dashboard
* Click on New Item
*  Provide the name as `Three-Tier-Frontend-Application` and select `Pipeline` and click on OK.
* Copy and paste from `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/blob/master/Jenkins-Pipeline-Code/Jenkinsfile-Frontend` in the Pipeline.
* Click Apply & Save.
* Now, click on the build
* Our pipeline was successful after a few common mistakes

Note: Do the changes in the Pipeline according to your project.


## Setup 10: Set up the Monitoring for our EKS Cluster. 

Prometheus and Grafana have already been installed by the Shell Script was executed.

Now move back to the Jenkins Server CLI, and check the service by the below command
```
kubectl get svc
```
Now, we need to access our Prometheus and Grafana consoles from outside of the cluster. For that, we need to change the Service type from ClusterType to LoadBalancer

Edit the `my-kube-prometheus-stack-prometheus` service
```
kubectl edit svc my-kube-prometheus-stack-prometheus
```
Modification `type` from ClusterType to LoadBalancer

Edit the `my-kube-prometheus-stack-grafana ` service
```
kubectl edit svc my-kube-prometheus-stack-grafana 
```
Modifiy `type` from ClusterType to LoadBalancer

Now, if you list again the service then, you will see the LoadBalancers DNS names
```
kubectl get svc
```
You can also validate from your console.

Now, access your Prometheus Dashboard
* Paste the (Prometheus-LB-DNS):9090 in your browser
* Click on Status and select Target.
* You will see a lot of Targets

Now, access your Grafana Dashboard
* Copy the ALB DNS of Grafana and paste it into your favorite browser.
* The username will be `admin` and the password will be `prom-operator` for your Grafana LogIn.
* Now, click on `Add you first Data Source`.
* Select Prometheus
* In the Connection, paste your (Prometheus-LB-DNS):9090.
* Click on Save & test.
* If the URL is correct, then you will see a green notification

Now, we will create a dashboard to visualize our Kubernetes Cluster Logs.
* Click on Dashboard.
* Once you click on Dashboard. You will see a lot of Kubernetes components monitoring.
* Let’s try to import a type of Kubernetes Dashboard.
* Click on New and select Import
* Provide `6417` ID and click on Load
* Select the data source(in this case prometheus-1) that you have created earlier and click on Import.

Note: 6417 is a unique ID from Grafana which is used to Monitor and visualize Kubernetes Data

Here, you go.

You can view your Kubernetes Cluster Data.

Feel free to explore the other details of the Kubernetes Cluster.


## Step 11: Deploy our Three-Tier Application using ArgoCD.
As our repository is private. So, we need to configure the Private Repository in ArgoCD.
* Go to ArgoCD and click on Settings and select Repositories
* Click on CONNECT REPO USING HTTPS
* `Type` : `git`
* `Project` : `default`
* `Repository URL` : `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git`
* Provide the username and GitHub Personal Access token and click on CONNECT.

If your Connection Status is Successful it means repository connected successfully.

Now, we will create our first application which will be a database.
* Click on APPLICATION -> NEW APP
* Provide the details as it is provided in the below.
* `Application Name`: `database`
* `Project Name`: `default`
* `SYNC POLICY` : `Automatic`
* `Repository URL` : `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git` (Select the same repository that you configured in the earlier step.)
* `Revision` : `HEAD`
* `Path` : `Kubernetes-Manifests-file/Database` (In the Path, provide the location where your Manifest files are presented and provide other things as shown in the below screenshot.)
* `Cluster URL` : `https://kubernetes.default.svc`
* `Namespace`: `three-tier`
* Click on CREATE.

While your database Application is starting to deploy, We will create an application for the backend.

Provide the details as it is provided in the below.
* Click on APPLICATION -> NEW APP
* Provide the details as it is provided in the below.
* `Application Name`: `backend`
* `Project Name`: `default`
* `SYNC POLICY` : `Automatic`
* `Repository URL` : `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git` (Select the same repository that you configured in the earlier step.)
* `Revision` : `HEAD`
* `Path` : `Kubernetes-Manifests-file/Backend` (In the Path, provide the location where your Manifest files are presented and provide other things as shown in the below screenshot.)
* `Cluster URL` : `https://kubernetes.default.svc`
* `Namespace`: `three-tier`
* Click on CREATE.

While your backend Application is starting to deploy, We will create an application for the frontend.
* `Application Name`: `frontend`
* `Project Name`: `default`
* `SYNC POLICY` : `Automatic`
* `Repository URL` : `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git` (Select the same repository that you configured in the earlier step.)
* `Revision` : `HEAD`
* `Path` : `Kubernetes-Manifests-file/Frontend` (In the Path, provide the location where your Manifest files are presented and provide other things as shown in the below screenshot.)
* `Cluster URL` : `https://kubernetes.default.svc`
* `Namespace`: `three-tier`
* Click on CREATE.

While your frontend Application is starting to deploy, We will create an application for the ingress.
* `Application Name`: `ingress`
* `Project Name`: `default`
* `SYNC POLICY` : `Automatic`
* `Repository URL` : `https://github.com/Mehar-Nafis/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git` (Select the same repository that you configured in the earlier step.)
* `Revision` : `HEAD`
* `Path` : `Kubernetes-Manifests-file` (In the Path, provide the location where your Manifest files are presented and provide other things as shown in the below screenshot.)
* `Cluster URL` : `https://kubernetes.default.svc`
* `Namespace`: `three-tier`
* Click on CREATE.

Once your Ingress application is deployed,  it will create an Application Load Balancer. You can check out the load balancer named with k8s-three.

Now, Copy the `ALB-DNS` and paste it into your browser. Refresh after 2 to 3 minutes in your browser to see the magic. You can play with the application by adding and deleting the records.

Now, you can see your `Grafana Dashboard` to view the EKS data such as pods, namespace, deployments, etc. If you want to monitor the `three-tier` namespace,  in the namespace, replace `three-tier` with another namespace.

If you observe, we have configured the Persistent Volume & Persistent Volume Claim. So, if the pods get deleted then, the data won’t be lost. The Data will be stored on the host machine.

To validate it, delete both Database pods. Now, the new pods will be started. And Your Application won’t lose a single piece of data.

## Conclusion:
In this comprehensive DevSecOps Kubernetes project, we successfully:
* Established `IAM user` and `Terraform` for AWS setup.
* Deployed `Jenkins` on AWS, configured tools, and integrated it with `Sonarqube`.
* Set up an `EKS cluster`, configured a `Load Balancer`, and established private `ECR repositories`.
* Implemented monitoring with `Helm`, `Prometheus`, and `Grafana`.
* Installed and configured `ArgoCD` for `GitOps practices`.
* Created `Jenkins pipelines` for `CI/CD`, deploying a Three-Tier application.
* Ensured `data persistence` with persistent volumes and claims.


# Cleanup
Execute the below commands on your Jenkins Server
```
eksctl delete cluster --name Three-Tier-K8s-EKS-Cluster --region us-west-1
```
```
aws ecr delete-repository --repository-name backend --force --region us-west-1
```
```
aws ecr delete-repository --repository-name frontend --force --region us-west-1
```
```
aws iam delete-policy --policy-arn arn:aws:iam::375728455575:policy/AWSLoadBalancerControllerIAMPolicy
```
```
exit
```


On the JumpServer execute the below commands
```
cd ~/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/Jenkins-Server-TF
```
```
terraform destroy -auto-approve
```
```
cd .. && cd JenkinsServer-Prerequiste/
```
```
aws s3 rm s3://mehar-devsecops-bucket/ --recursive
```
```
terraform destroy -auto-approve
```

Now terminate your JumpServer from the Console.





