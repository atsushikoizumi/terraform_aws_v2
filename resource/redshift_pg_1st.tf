# aws_redshift_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_parameter_group
resource "aws_redshift_parameter_group" "redshift_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-clspg-redshift-1st"
  family = "redshift-1.0"

  parameter {
    name  = "auto_analyze"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "require_ssl"
    value = "false"
  }

  parameter {
    name  = "search_path"
    value = "$user, public"
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_redshift_snapshot_schedule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_snapshot_schedule
resource "aws_redshift_snapshot_schedule" "redshift_1st" {
  identifier = "${var.tags_owner}-${var.tags_env}-1st"
  definitions = [
    "cron(0 2 *)", # AM2:00 everyday, cron(m h d)
  ]

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
