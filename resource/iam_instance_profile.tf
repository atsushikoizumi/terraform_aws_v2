# aws_iam_instance_profile
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.tags_owner}-${var.tags_env}-ec2_profile"
  role = aws_iam_role.ec2.name
}