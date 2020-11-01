# aws_rds_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster
resource "aws_rds_cluster" "aurora_postgre_1st" {
  cluster_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-postgres-1st"
  engine             = "aurora-postgresql"
  engine_version     = "11.8"
  engine_mode        = "provisioned" # global,multimaster,parallelquery,serverless, default provisioned
  database_name      = "aurora"
  master_username    = "aurora"
  master_password    = "Admin123!"

  # storage
  storage_encrypted = true # declare KMS key ARN if true, default false
  # kms_key_id               = ""  # set KMS ARN if storage_encrypted is true, default "aws/rds"

  # network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  port                   = 5432

  # iam roles
  # https://github.com/terraform-aws-modules/terraform-aws-rds-aurora/issues/129
  # https://github.com/terraform-providers/terraform-provider-aws/issues/9552

  # backup snapshot
  backup_retention_period   = 3                           # must be between 1 and 35. default 1 (days)
  copy_tags_to_snapshot     = true                        # default false
  deletion_protection       = false                       # default false
  skip_final_snapshot       = true                        # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-postgres-1st" # must be provided if skip_final_snapshot is set to false.

  # monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # window time
  preferred_backup_window      = "00:40-01:40"
  preferred_maintenance_window = "Mon:03:00-Mon:04:00"

  # options
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_postgre_1st.name

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_rds_cluster_instance
resource "aws_rds_cluster_instance" "aurora_postgre_1st" {
  count              = 1
  identifier         = "${var.tags_owner}-${var.tags_env}-cls-ins-aurora-postgres-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_postgre_1st.cluster_identifier
  instance_class     = "db.t3.medium"
  engine             = "aurora-postgresql"
  engine_version     = "11.8"

  # netowrok
  #availability_zone = ""   # eu-west-1a,eu-west-1b,eu-west-1c

  # monitoring
  performance_insights_enabled = false                           # default false
  monitoring_interval          = 60                              # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn # https://github.com/terraform-providers/terraform-provider-aws/issues/315

  # options
  db_parameter_group_name    = aws_db_parameter_group.aurora_postgre_1st.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
