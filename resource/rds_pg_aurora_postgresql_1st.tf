# aws_rds_cluster_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group
resource "aws_rds_cluster_parameter_group" "aurora_postgre_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-clspg-aurora-postgre-1st"
  family = "aurora-postgresql11"
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
    value = "ddl,misc,role"
  }
  parameter {
    name  = "pgaudit.role"
    value = "rds_pgaudit"
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
}

# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "aurora_postgre_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-aurora-postgre-1st"
  family = "aurora-postgresql11"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
