# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "oracle_2nd" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-oracle-2nd"
  family = "oracle-se2-19"

  parameter {
    name         = "audit_trail"
    value        = "XML,EXTENDED"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "audit_sys_operations"
    value        = false
    apply_method = "pending-reboot"
  }

  # lifecycle
  lifecycle {
    ignore_changes = [
      parameter
    ]
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_db_option_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_option_group
resource "aws_db_option_group" "oracle_2nd" {
  name                 = "${var.tags_owner}-${var.tags_env}-opg-oracle-2nd"
  engine_name          = "oracle-se2"
  major_engine_version = 19

  option {
    option_name                    = "S3_INTEGRATION"
    db_security_group_memberships  = []
    port                           = 0
    version                        = "1.0"
    vpc_security_group_memberships = []
  }

  option {
    option_name                    = "Timezone"
    db_security_group_memberships  = []
    port                           = 0
    vpc_security_group_memberships = []

    option_settings {
      name  = "TIME_ZONE"
      value = "Asia/Tokyo"
    }
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}


# aws_db_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance
resource "aws_db_instance" "oracle_2nd" {
  identifier     = "${var.tags_owner}-${var.tags_env}-db-oracle-2nd"
  instance_class = "db.t3.medium"
  engine         = "oracle-se2"
  engine_version = "19.0.0.0.ru-2020-07.rur-2020-07.r1"
  license_model  = "license-included"
  multi_az       = false      # default false
  name           = "MASTERDB" # must be upper, default ORCL
  username       = "MASTERUSER"
  password       = var.db_master_password.oracle

  # storage
  storage_type          = "gp2" # The default is "io1", "gp2", "standard" (magnetic)
  allocated_storage     = 20    # depends on storage_type
  max_allocated_storage = 1000  # Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling.
  storage_encrypted     = true  # declare KMS key ARN if true, default false
  # kms_key_id          = ""    # set KMS ARN if storage_encrypted is true, default "aws/rds"

  # network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  port                   = 1521

  # monitoring
  performance_insights_enabled    = false                           # default false
  monitoring_interval             = 60                              # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn # https://github.com/terraform-providers/terraform-provider-aws/issues/315
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]

  # backup snapshot
  backup_retention_period   = 8                                                 # default 7 (days). 0 = disabled.
  backup_window             = "17:00-17:30"                                     # UTC, must not overlap with maintenance_window.
  copy_tags_to_snapshot     = true                                              # default false
  delete_automated_backups  = true                                              # default true
  deletion_protection       = false                                             # default false
  skip_final_snapshot       = true                                              # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-db-oracle-2nd" # must be provided if skip_final_snapshot is set to false.

  # options
  parameter_group_name       = aws_db_parameter_group.oracle_2nd.name
  option_group_name          = aws_db_option_group.oracle_2nd.name
  character_set_name         = "UTF8"                # Oracle and Microsoft SQL
  auto_minor_version_upgrade = false                 # default true
  maintenance_window         = "Sun:18:00-Sun:19:00" # UTC

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_db_instance_role_association
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance_role_association
resource "aws_db_instance_role_association" "oracle_2nd" {
  db_instance_identifier = aws_db_instance.oracle_2nd.id
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.rds.arn
}