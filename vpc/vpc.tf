# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name  = "aqua-common-vpc"
    Owner = "koizumi"
    Env   = "common"
  }
}

data "aws_vpc" "common_vpc" {
  depends_on = [aws_vpc.vpc]
  filter {
    name   = "tag:Name"
    values = ["aqua-common-vpc"]
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "aqua-common-igw"
    Owner = "koizumi"
    Env   = "common"
  }
}

# VPC endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.eu-north-1.s3"

  tags = {
    Name  = "aqua-common-vpc-endpoint"
    Owner = "koizumi"
    Env   = "common"
  }
}

# aws_route_table public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "aqua-common-route-public"
    Owner = "koizumi"
    Env   = "common"
  }
}

# vpc endpoint for main route
resource "aws_vpc_endpoint_route_table_association" "main" {
  route_table_id  = data.aws_vpc.common_vpc.main_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# vpc endpoint for public route
resource "aws_vpc_endpoint_route_table_association" "public" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}