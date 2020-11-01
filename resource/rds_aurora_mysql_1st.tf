# aws_rds_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster
resource "aws_rds_cluster" "aurora_mysql_1st" {
  cluster_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-mysql-1st"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.08.1"
  engine_mode        = "provisioned" # global,multimaster,parallelquery,serverless, default provisioned
  master_username    = "aurora"
  master_password    = "Admin123!"
  database_name      = "aurora"

  # storage
  storage_encrypted = false # declare KMS key ARN if true, default false
  # kms_key_id               = ""  # set KMS ARN if storage_encrypted is true, default "aws/rds"

  # network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  port                   = 3306

  # roles
  iam_roles = [aws_iam_role.rds.arn]

  # backup snapshot
  backtrack_window          = 0                                        # default 0
  backup_retention_period   = 3                                        # must be between 1 and 35. default 1 (days)
  copy_tags_to_snapshot     = true                                     # default false
  deletion_protection       = false                                    # default false
  skip_final_snapshot       = true                                     # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-mysql-1st" # must be provided if skip_final_snapshot is set to false.

  # monitoring
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # options
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql_1st.name

  # window time
  preferred_backup_window      = "02:00-02:30"
  preferred_maintenance_window = "Mon:03:00-Mon:04:00"

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_rds_cluster_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance
resource "aws_rds_cluster_instance" "aurora_mysql_1st" {
  count              = 1
  identifier         = "${var.tags_owner}-${var.tags_env}-cls-ins-aurora-mysql-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_mysql_1st.cluster_identifier
  instance_class     = "db.t3.small"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.08.1"

  # netowrok
  # availability_zone = ""   # eu-west-1a,eu-west-1b,eu-west-1c

  # monitoring
  performance_insights_enabled = false                            # default false
  monitoring_interval          = 60                               # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn  # https://github.com/terraform-providers/terraform-provider-aws/issues/315

  # options
  db_parameter_group_name    = aws_db_parameter_group.aurora_mysql_1st.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}