resource "aws_ecr_repository" "logicalbackup" {
  name                 = "${var.tags_owner}-${var.tags_env}-logicalbackup"
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
