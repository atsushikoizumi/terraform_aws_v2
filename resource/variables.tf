# provider.tf
variable tags_owner {}
variable tags_env {}
variable ec2_subnet {}
variable rds_subnet {}
variable redshift_subnet {}
variable allow_ip {}

# key pair
variable public_key_path {}

# vpc
variable vpc_id {}
variable vpc_cidr_block {}
variable rt_id_public {}
variable rt_id_private {}
