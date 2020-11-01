# aws_db_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance
resource "aws_db_instance" "sqlserver_1st" {
  identifier     = "${var.tags_owner}-${var.tags_env}-sqlserver-1st"
  instance_class = "db.r5.large"
  engine         = "sqlserver-se"
  engine_version = "14.00.3281.6.v1"
  license_model  = "license-included"
  multi_az       = false # default false
  username       = "aquadba"
  password       = "Admin123!"

  # storage
  storage_type          = "gp2" # The default is "io1", "gp2", "standard" (magnetic)
  allocated_storage     = 20    # depends on storage_type
  max_allocated_storage = 1000  # Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling.
  storage_encrypted     = true  # declare KMS key ARN if true, default false
  # kms_key_id               = ""  # set KMS ARN if storage_encrypted is true, default "aws/rds"

  # network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  port                   = 1433

  # monitoring
  performance_insights_enabled    = false                           # default false
  monitoring_interval             = 60                              # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn # https://github.com/terraform-providers/terraform-provider-aws/issues/315
  enabled_cloudwatch_logs_exports = ["agent", "error"]

  # backup snapshot
  backup_retention_period   = 1                             # default 7 (days). 0 = disabled.
  copy_tags_to_snapshot     = true                          # default false
  delete_automated_backups  = true                          # default true
  deletion_protection       = false                         # default false
  skip_final_snapshot       = true                          # default false
  final_snapshot_identifier = "${var.tags_owner}-${var.tags_env}-sqlserver-1st" # must be provided if skip_final_snapshot is set to false.

  # window time
  backup_window      = "01:00-01:30" # must not overlap with maintenance_window.
  maintenance_window = "Mon:02:00-Mon:03:00"

  # options
  parameter_group_name       = aws_db_parameter_group.sqlserver_1st.name
  option_group_name          = aws_db_option_group.sqlserver_1st.name
  character_set_name         = "Japanese_CI_AS" # Oracle and Microsoft SQL
  timezone                   = "Tokyo Standard Time"
  auto_minor_version_upgrade = false # default true

  # tags
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}