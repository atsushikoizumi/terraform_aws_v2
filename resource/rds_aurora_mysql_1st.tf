# aws_rds_cluster_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group
resource "aws_rds_cluster_parameter_group" "aurora_mysql_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-clspg-aurora-mysql-1st"
  family = "aurora-mysql5.7"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_connection"
    value = "utf8mb4_bin"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_bin"
  }
  parameter {
    name  = "time_zone"
    value = "asia/tokyo"
  }
  parameter {
    name  = "server_audit_events"
    value = "connect,query"
  }
  parameter {
    name  = "server_audit_excl_users"
    value = "rdsadmin"
  }
  parameter {
    name  = "server_audit_logging"
    value = 1
  }
  parameter {
    name  = "server_audit_logs_upload"
    value = 1
  }
  parameter {
    name  = "slow_query_log"
    value = 1
  }

  # lifecycle
  lifecycle {
    ignore_changes = [
      parameter
    ]
  }
}

# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "aurora_mysql_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-aurora-mysql-1st"
  family = "aurora-mysql5.7"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}


# aws_rds_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster
resource "aws_rds_cluster" "aurora_mysql_1st" {
  cluster_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-mysql-1st"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.08.1"
  engine_mode        = "provisioned" # global,multimaster,parallelquery,serverless, default provisioned
  database_name      = "masterdb"
  master_username    = "masteruser"
  master_password    = var.db_master_password.mysql

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
  backtrack_window          = 0                                                        # default 0
  backup_retention_period   = 8                                                        # must be between 1 and 35. default 1 (days)
  copy_tags_to_snapshot     = true                                                     # default false
  deletion_protection       = false                                                    # default false
  skip_final_snapshot       = true                                                     # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-mysql-1st" # must be provided if skip_final_snapshot is set to false.

  # monitoring
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # options
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql_1st.name

  # window time
  preferred_backup_window      = "17:00-17:30"         # UTC
  preferred_maintenance_window = "Sun:18:00-Sun:19:00" # UTC

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
  identifier         = "${var.tags_owner}-${var.tags_env}-ins-aurora-mysql-1st-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_mysql_1st.cluster_identifier
  instance_class     = "db.t3.small"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.08.1"

  # netowrok
  # availability_zone = ""   # eu-west-1a,eu-west-1b,eu-west-1c

  # monitoring
  performance_insights_enabled = false                           # default false
  monitoring_interval          = 60                              # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn # https://github.com/terraform-providers/terraform-provider-aws/issues/315

  # options
  db_parameter_group_name    = aws_db_parameter_group.aurora_mysql_1st.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}