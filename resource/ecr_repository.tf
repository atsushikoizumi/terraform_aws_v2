#
# 論理バックアップ用イメージ
#  logicalbackup_mypg: aurora mysql,aurora postgresql
#  logicalbackup_orss: rds oracle,rds sqlserver
#
resource "aws_ecr_repository" "logicalbackup_mypg" {
  name                 = "${var.tags_owner}-${var.tags_env}-logicalbackup-mypg"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
