## Prerequisites:
Before starting the project, ensure you have the following prerequisites:

* An AWS account with the necessary permissions to create resources.
* Terraform and AWS CLI installed on your local machine.
* Basic familiarity with Kubernetes, Docker, Jenkins, and DevOps principles.

## Setup
### Step 1: Create an IAM user and generate the AWS Access key
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

