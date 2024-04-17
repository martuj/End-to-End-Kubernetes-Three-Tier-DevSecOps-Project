resource "aws_s3_bucket" "example" {
  bucket = "mehar-devsecops-bucket"

  tags = {
    Name    = "mehar-devsecops-bucket"
    Project = "DevSecOps Project"
  }
}
