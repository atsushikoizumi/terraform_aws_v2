# 変更不可

# provider.tf
variable tags_owner {}
variable tags_env {}
variable ec2_subnet {}
variable rds_subnet {}
variable redshift_subnet {}
variable allow_ip {}
variable aws_account_id {}

# key pair
variable public_key_path {}
variable private_key_path {}

# github
variable git_account {}
variable git_pass {}

# vpc
variable vpc_id {}
variable vpc_cidr_block {}
variable rt_id_public {}
variable rt_id_private {}

# lambda
variable resource_stop_flag {}
variable layer_zip {}
variable function_zip {}