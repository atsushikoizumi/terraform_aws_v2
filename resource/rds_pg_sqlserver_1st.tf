# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "sqlserver_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-sqlserver-1st"
  family = "sqlserver-se-14.0"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_db_option_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_option_group
resource "aws_db_option_group" "sqlserver_1st" {
  name                 = "${var.tags_owner}-${var.tags_env}-opg-sqlserver-1st"
  engine_name          = "sqlserver-se"
  major_engine_version = "14.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds.arn
    }
  }

  option {
    option_name = "SQLSERVER_AUDIT"

    option_settings {
      name  = "ENABLE_COMPRESSION"
      value = true
    }
    option_settings {
      name  = "S3_BUCKET_ARN"
      value = "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs/audit/"
    }
    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds.arn
    }
    option_settings {
      name  = "RETENTION_TIME"
      value = 0
    }

  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
