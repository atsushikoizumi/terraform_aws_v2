# ec2
resource "aws_subnet" "ec2" {
  for_each                = var.ec2_subnet
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 11, each.value)
  map_public_ip_on_launch = true # Required to set Public IP when creating EC2
  availability_zone       = each.key
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-ec2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_route_table_association" "ec2" {
  for_each       = var.ec2_subnet
  subnet_id      = aws_subnet.ec2[each.key].id
  route_table_id = var.rt_id_public
}

# rds
resource "aws_subnet" "rds" {
  for_each                = var.rds_subnet
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 11, each.value)
  map_public_ip_on_launch = false
  availability_zone       = each.key
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-rds"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_route_table_association" "rds" {
  for_each       = var.rds_subnet
  subnet_id      = aws_subnet.rds[each.key].id
  route_table_id = var.rt_id_private
}

# redshift
resource "aws_subnet" "redshift" {
  for_each                = var.redshift_subnet
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 11, each.value)
  map_public_ip_on_launch = false
  availability_zone       = each.key
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-redshift"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_route_table_association" "redshift" {
  for_each       = var.redshift_subnet
  subnet_id      = aws_subnet.redshift[each.key].id
  route_table_id = var.rt_id_private
}