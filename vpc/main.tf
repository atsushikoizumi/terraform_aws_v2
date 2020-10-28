# Terraform version
terraform {
  # https://www.terraform.io/docs/backends/types/s3.html
  backend "s3" {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/isid/resources.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
  required_version = "= 0.13.5"
}

# Provider
# https://www.terraform.io/docs/providers/index.html
# https://github.com/terraform-aws-modules
provider "aws" {
  version                 = "3.12.0"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "isid_koizumi"
  region                  = "ap-northeast-1"
}

# terraform_remote_state
# https://www.terraform.io/docs/providers/terraform/d/remote_state.html
data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/isid/global.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
}

# terraform_remote_state
# https://www.terraform.io/docs/providers/terraform/d/remote_state.html
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/isid/vpc.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
}

data "terraform_remote_state" "parameter" {
  backend = "s3"

  config = {
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/isid/parameter.tfstate"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
}

# module
# https://dev.classmethod.jp/articles/directory-layout-bestpractice-in-terraform/
module "dev" {
  source = "../../"

  tags_owner      = var.tags_owner
  rds_az          = var.rds_az
  allow_ip        = var.allow_ip
  public_key_path = var.public_key_path
  git_email       = var.git_email
  git_account     = var.git_account
  git_pass        = var.git_pass

  # global
  iam_instance_profile_ec2_nm = data.terraform_remote_state.global.outputs.iam_instance_profile_ec2_nm
  iam_role_rds_monitoring_arn = data.terraform_remote_state.global.outputs.iam_role_rds_monitoring_arn
  iam_role_rds_arn            = data.terraform_remote_state.global.outputs.iam_role_rds_arn
  iam_role_redshift_arn       = data.terraform_remote_state.global.outputs.iam_role_redshift_arn
  s3_bucket_logs_arn          = data.terraform_remote_state.global.outputs.s3_bucket_logs_arn

  # vpc
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr
  rt_id_public   = data.terraform_remote_state.vpc.outputs.route_table_public
  rt_id_private  = data.terraform_remote_state.vpc.outputs.route_table_private

  # parameter
  rds_cpg_am1 = data.terraform_remote_state.parameter.outputs.rds_cpg_am1
  rds_dpg_am1 = data.terraform_remote_state.parameter.outputs.rds_dpg_am1
  rds_cpg_ap1 = data.terraform_remote_state.parameter.outputs.rds_cpg_ap1
  rds_dpg_ap1 = data.terraform_remote_state.parameter.outputs.rds_dpg_ap1
  rds_dpg_o1  = data.terraform_remote_state.parameter.outputs.rds_dpg_o1
  rds_dog_o1  = data.terraform_remote_state.parameter.outputs.rds_dog_o1
  rds_dpg_s1  = data.terraform_remote_state.parameter.outputs.rds_dpg_s1
  rds_dog_s1  = data.terraform_remote_state.parameter.outputs.rds_dog_s1
  rs_rpg_r1   = data.terraform_remote_state.parameter.outputs.rs_rpg_r1
  rs_rss_r1   = data.terraform_remote_state.parameter.outputs.rs_rss_r1
}
