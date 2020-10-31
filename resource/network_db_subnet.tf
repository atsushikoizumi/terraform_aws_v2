# DB Subnet
# https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html
resource "aws_db_subnet_group" "rds" {
  name = "${var.tags_owner}-${var.tags_env}-subnet"
  subnet_ids = [
    aws_subnet.rds["eu-north-1a"].id,
    aws_subnet.rds["eu-north-1b"].id,
    aws_subnet.rds["eu-north-1c"].id
  ]
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}


# aws_redshift_subnet_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_subnet_group
resource "aws_redshift_subnet_group" "redshift" {
  name = "${var.tags_owner}-${var.tags_env}-subnet"
  subnet_ids = [
    aws_subnet.redshift["eu-north-1a"].id,
    aws_subnet.redshift["eu-north-1b"].id,
    aws_subnet.redshift["eu-north-1c"].id
  ]

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
