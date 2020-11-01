# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "oracle_1st" {
  name   = "${var.tags_owner}-${var.tags_env}-pg-oracle-1st"
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

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# aws_db_option_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_option_group
resource "aws_db_option_group" "oracle_1st" {
  name                 = "${var.tags_owner}-${var.tags_env}-opg-oracle-1st"
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
