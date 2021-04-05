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
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allow_ip
  }

  ingress {
    description = "Full Access From Self SecurityGroup"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

/*## allways on
  ingress {
    description = "RPC"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "Cluster Administrator"
    from_port   = 137
    to_port     = 137
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true 
  }

  ingress {
    description = "Cluster Administrator"
    from_port   = 137
    to_port     = 137
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true 
  }

  ingress {
    description = "SMB"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "SQLServer"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "SQLServer"
    from_port   = 1434
    to_port     = 1434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "SQLServer"
    from_port   = 1434
    to_port     = 1434
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true 
  }

  ingress {
    description = "Cluster Service"
    from_port   = 3343
    to_port     = 3343
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "Cluster Service"
    from_port   = 3343
    to_port     = 3343
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "mice server"
    from_port   = 5022
    to_port     = 5022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "WinRM"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "Randomly allocated high TCP ports"
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true
  }

  ingress {
    description = "Randomly allocated high UDP ports"
    from_port   = 49152
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true 
  }

  ingress {
    description = "ICMP"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    #self        = true 
  }
*/
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