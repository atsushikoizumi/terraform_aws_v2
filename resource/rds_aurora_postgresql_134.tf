resource "aws_rds_cluster_parameter_group" "aurora_postgre_13" {
  name   = "${var.tags_owner}-${var.tags_env}-clspg-aurora-postgre-13"
  family = "aurora-postgresql13"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }

  # install libraries
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_hint_plan,pgaudit"
    apply_method = "pending-reboot"
  }

  # audit setting
  parameter {
    name  = "pgaudit.log_catalog"
    value = 1
  }
  parameter {
    name  = "pgaudit.log_parameter"
    value = 1
  }
  parameter {
    name  = "pgaudit.log_relation"
    value = 1
  }
  parameter {
    name  = "pgaudit.log_statement_once"
    value = 1
  }
  parameter {
    name  = "pgaudit.log"
    value = "None"
  }
  parameter {
    name  = "pgaudit.role"
    value = "rds_pgaudit"
  }
  parameter {
    name  = "log_connections"
    value = 1
  }
  parameter {
    name  = "log_disconnections"
    value = 1
  }

  # no local
  parameter {
    name  = "lc_messages"
    value = "C"
  }
  parameter {
    name  = "lc_monetary"
    value = "C"
  }
  parameter {
    name  = "lc_numeric"
    value = "C"
  }
  parameter {
    name  = "lc_time"
    value = "C"
  }

  # lifecycle
  /*lifecycle {
    ignore_changes = [
      parameter
    ]
  }*/
}

resource "aws_db_parameter_group" "aurora_postgre_13" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-aurora-postgre-13"
  family = "aurora-postgresql13"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_rds_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster
resource "aws_rds_cluster" "aurora_postgre_134" {
  cluster_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-postgres-134"
  engine             = "aurora-postgresql"
  engine_version     = "13.4"
  engine_mode        = "provisioned" # global,multimaster,parallelquery,serverless, default provisioned
  database_name      = "masterdb"
  master_username    = "masteruser"
  master_password    = var.db_master_password.postgresql

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
  backup_retention_period   = 8                                                           # must be between 1 and 35. default 1 (days)
  copy_tags_to_snapshot     = true                                                        # default false
  deletion_protection       = false                                                       # default false
  skip_final_snapshot       = true                                                        # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-cls-aurora-postgres-134" # must be provided if skip_final_snapshot is set to false.

  # monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # window time
  preferred_backup_window      = "17:00-17:30"         # UTC
  preferred_maintenance_window = "Sun:18:00-Sun:19:00" # UTC

  # options
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_postgre_13.name

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_rds_cluster_instance
resource "aws_rds_cluster_instance" "aurora_postgre_134" {
  count              = 1
  identifier         = "${var.tags_owner}-${var.tags_env}-postgre-134-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_postgre_134.cluster_identifier
  instance_class     = "db.r5.large"
  engine             = "aurora-postgresql"
  engine_version     = "13.4"

  # netowrok
  #availability_zone = ""   # eu-west-1a,eu-west-1b,eu-west-1c

  # monitoring
  performance_insights_enabled = false                           # default false
  monitoring_interval          = 60                              # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn # https://github.com/terraform-providers/terraform-provider-aws/issues/315

  # options
  db_parameter_group_name    = aws_db_parameter_group.aurora_postgre_13.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
