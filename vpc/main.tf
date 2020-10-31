terraform {
  backend "s3" {
    region                  = "eu-west-1"
    bucket                  = "aws-aqua-terraform"
    key                     = "koizumi/dba-test/vpc.tfstate"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
  }
  required_version = "0.13.5"
}

provider "aws" {
  version                 = "3.12.0"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "koizumi"
  region                  = "eu-north-1"
}

