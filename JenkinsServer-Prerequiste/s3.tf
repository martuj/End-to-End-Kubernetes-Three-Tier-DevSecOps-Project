resource "aws_s3_bucket" "example" {
  bucket = "mehar-devsecops-bucket-1"

  tags = {
    Name    = "mehar-devsecops-bucket-1"
    Project = "DevSecOps Project"
  }
}
