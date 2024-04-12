output "Public_ip" {
  description = "Public IP of the instance"
  value = aws_instance.ec2.public_ip
}
