# ec2
resource "aws_security_group" "ec2" {
  name        = "${var.tags_owner}-${var.tags_env}-sg-ec2"
  description = "koizumi work Security Group for EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
    self        = true
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
    self        = true
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
    self        = true
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
    self        = true
  }

  ingress {
    description = "efs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-sg-ec2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# rds
resource "aws_security_group" "rds" {
  name        = "${var.tags_owner}-${var.tags_env}-sg-rds"
  description = "koizumi work Security Group for RDS"
  vpc_id      = var.vpc_id
  ingress {
    description = "ALL Ports Allow from EC2"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    security_groups = [
      aws_security_group.ec2.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-sg-rds"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# redshift
resource "aws_security_group" "redshift" {
  name        = "${var.tags_owner}-${var.tags_env}-sg-redshift"
  description = "koizumi work Security Group for Redshift"
  vpc_id      = var.vpc_id
  ingress {
    description = "ALL Ports Allow from EC2,RDS"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ec2.id,
      aws_security_group.rds.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-sg-redshift"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}