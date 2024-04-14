resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = "t2.2xlarge"
  key_name               = var.key-name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 30
  }
  user_data = templatefile("./tools-install.sh", {})

  tags = {
    Name = var.instance-name
  }

  provisioner "file" {
    source      = "EKSClusterSetup.sh"   # Source path of create.sh
    destination = "/home/ubuntu/EKSClusterSetup.sh"  # Destination path on EC2 instance
  }

#  provisioner "file" {
#    source      = "delete.sh"  # Source path of delete.sh
#    destination = "/home/ubuntu/setup.sh"  # Destination path on EC2 instance
#  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/ubuntu/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/JenkinsServer-Prerequiste/devsecops-key")  # Path to your private key
    host        = self.public_ip  # Assuming you want to use the public IP
  }
}
