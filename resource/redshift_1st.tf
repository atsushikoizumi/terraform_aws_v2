# aws_redshift_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_cluster
resource "aws_redshift_cluster" "redshift_1st" {
  cluster_identifier = "${var.tags_owner}-${var.tags_env}-redshift-cls-1st"
  database_name      = "masterdb"
  master_username    = "masteruser"
  master_password    = var.db_master_password.redshift
  node_type          = "dc2.large"
  cluster_version    = "1.0"

  # option
  cluster_parameter_group_name = aws_redshift_parameter_group.redshift_1st.name

  # iam role
  iam_roles = [aws_iam_role.rds.arn]

  # single or malti
  cluster_type    = "single-node"
  number_of_nodes = 1

  # encrypted
  encrypted = false
  # kms_key_id = kms_key_id  # encrypted needs to be set to true.

  # network
  publicly_accessible  = false # the cluster can be accessed from a public network. Default is true.
  enhanced_vpc_routing = false # If true , enhanced VPC routing is enabled.
  # elastic_ip = 
  port                      = 5439
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  # logging
  # https://docs.aws.amazon.com/ja_jp/redshift/latest/mgmt/db-auditing.html
  logging {
    enable        = true # must be set s3 bucket policy
    bucket_name   = "${var.tags_owner}-${var.tags_env}-logs"
    s3_key_prefix = "audit/${var.tags_owner}-${var.tags_env}-redshift-cls-1st/"
  }

  # backup
  automated_snapshot_retention_period = 3
  skip_final_snapshot                 = true
  # final_snapshot_identifier =    # skip_final_snapshot must be false.

  # maintenance window
  preferred_maintenance_window = "Sun:18:00-Sun:19:00"
  allow_version_upgrade        = true # major version upgrades can be applied during the maintenance window

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_redshift_snapshot_schedule_association
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_snapshot_schedule_association
resource "aws_redshift_snapshot_schedule_association" "redshift_1st" {
  cluster_identifier  = aws_redshift_cluster.redshift_1st.id
  schedule_identifier = aws_redshift_snapshot_schedule.redshift_1st.identifier
}
