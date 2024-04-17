#!/bin/bash

# Step 1: Set the host name
echo "Setting the hostname..."
sudo hostnamectl set-hostname JumpServer 

# Update package lists and install required packages
echo "Updating package lists..."
sudo apt update
echo "Installing wget and unzip..."
sudo apt install wget unzip -y

# Download and install Terraform
echo "Downloading Terraform..."
wget https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip
echo "Unzipping Terraform..."
unzip terraform_1.6.3_linux_amd64.zip
echo "Moving Terraform binary to /usr/local/bin..."
sudo mv terraform /usr/local/bin
echo "Cleaning up..."
rm terraform_1.6.3_linux_amd64.zip

# Install AWS CLI
echo "Installing AWS CLI..."
sudo apt-get install python3-pip -y
sudo pip3 install awscli

# Restart required services
echo "Restarting polkit.service..."
yes | sudo systemctl restart polkit.service

# Start an interactive bash session
echo "Starting interactive bash session..."
bash
