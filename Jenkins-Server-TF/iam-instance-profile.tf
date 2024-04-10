resource "aws_iam_instance_profile" "instance-profile" {
  name = "Jenkins-instance-profile-devsecops"
  role = aws_iam_role.iam-role.name
}
