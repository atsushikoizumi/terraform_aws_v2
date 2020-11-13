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
