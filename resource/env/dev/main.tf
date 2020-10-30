# Terraform version
terraform {
  backend "s3" {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/aqua/resources.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
  required_version = "0.13.5"
}

# Provider
provider "aws" {
  version                 = "3.12.0"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "koizumi"
  region                  = "eu-north-1"
}

# terraform_remote_state
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/aqua/vpc.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
}

# module
module "resource" {
  source = "../../../resource/"

  tags_owner      = var.tags_owner
  tags_env        = var.tags_env
  ec2_subnet      = var.ec2_subnet
  rds_subnet      = var.rds_subnet
  redshift_subnet = var.redshift_subnet
  allow_ip        = var.allow_ip
  public_key_path = var.public_key_path

  # vpc
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr
  rt_id_public   = data.terraform_remote_state.vpc.outputs.route_table_public
  rt_id_private  = data.terraform_remote_state.vpc.outputs.route_table_private
}
