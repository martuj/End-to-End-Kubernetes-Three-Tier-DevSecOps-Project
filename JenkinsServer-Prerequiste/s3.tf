resource "aws_s3_bucket" "example" {
  bucket = "mehar-devsecops-bucket1"

  tags = {
    Name    = "mehar-devsecops-bucket1"
    Project = "DevSecOps Project"
  }
}
