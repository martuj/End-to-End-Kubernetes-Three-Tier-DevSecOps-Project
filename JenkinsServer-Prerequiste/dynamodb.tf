resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "Mehar-DevSecOps-LockTable"
  hash_key       = "LockID"
  write_capacity = 5
  read_capacity  = 5

  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags = {
    Name    = "Mehar-DevSecOps-LockTable"
    Project = "DevSecOps"
  }
}
