#
# ver 1.0
#

# Terraform
terraform {
  required_version = "0.14.9"
  backend "s3" {
    region                  = "eu-west-1"
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/dba-test/dev/resource.tfstate"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.3.0"
    }
  }
}

# Provider
provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "koizumi"
}

# Remote state vpc
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region                  = "eu-west-1"
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/dba-test/vpc.tfstate"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"

  }
}

# module
module "resource" {
  source = "../../../resource/"

  # send variable.value to resource
  tags_owner          = var.tags_owner
  tags_env            = var.tags_env
  ec2_subnet          = var.ec2_subnet
  rds_subnet          = var.rds_subnet
  redshift_subnet     = var.redshift_subnet
  allow_ip            = var.allow_ip
  public_key_path     = var.public_key_path
  git_account         = var.git_account
  git_pass            = var.git_pass
  resource_stop_flag  = var.resource_stop_flag
  layer_zip           = var.layer_zip
  resource_stop_zip   = var.resource_stop_zip
  resource_start_zip  = var.resource_start_zip
  private_key_path    = var.private_key_path
  db_master_password  = var.db_master_password
  join_linux          = var.join_linux
  logical_backup_flag = var.logical_backup_flag
  ssh_key             = var.ssh_key
  aws_account_id      = var.aws_account_id
  aws_account_user    = var.aws_account_user

  # get output.value from vpc
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr
  rt_id_public   = data.terraform_remote_state.vpc.outputs.route_table_public
  rt_id_private  = data.terraform_remote_state.vpc.outputs.route_table_private

}
