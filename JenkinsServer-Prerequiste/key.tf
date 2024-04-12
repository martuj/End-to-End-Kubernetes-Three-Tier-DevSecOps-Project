#Generating the Key pair
resource "tls_private_key" "devsecops_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Storing the Public key in AWS
resource "aws_key_pair" "devsecops-key" {
  key_name   = "devsecops-key"
  public_key = tls_private_key.devsecops_key_pair.public_key_openssh  #Passing the Public Key 
}


#Store the private Key on Local
resource "local_file" "mykey_private" {
  content = tls_private_key.devsecops_key_pair.private_key_pem
  filename = "devsecops-key"
}

