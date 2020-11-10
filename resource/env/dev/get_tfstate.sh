#!/bin/bash

aws s3 cp s3://aws-aqua-terraform/koizumi/dba-test/resource_dev.tfstate ./
aws s3 cp s3://aws-aqua-terraform/koizumi/isid/resources.tfstate ./
#aws s3 cp s3://aws-aqua-terraform/koizumi/dba-test/resource_stg.tfstate ./
#aws s3 cp s3://aws-aqua-terraform/koizumi/dba-test/resource_prd.tfstate ./
#aws s3 cp s3://aws-aqua-terraform/koizumi/dba-test/vpc.tfstate ./

