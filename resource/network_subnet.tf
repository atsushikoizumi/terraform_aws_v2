# Subnet
# https://www.terraform.io/docs/providers/aws/r/subnet.html
# https://www.terraform.io/docs/configuration/functions/cidrsubnet.html
resource "aws_subnet" "ec2" {
  for_each                = var.ec2_subnet
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 12, each.value)
  map_public_ip_on_launch = true # Required to set Public IP when creating EC2
  availability_zone       = each.key
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-ec2"
    Owner = var.tags_owner
  }
}
