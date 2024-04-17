resource "aws_s3_bucket" "example" {
  bucket = "devsecops-bucket"

  tags = {
    Name    = "devsecops-bucket"
    Project = "DevSecOps Project"
  }
}
