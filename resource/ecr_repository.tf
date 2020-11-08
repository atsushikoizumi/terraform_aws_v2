# fargate ecr
resource "aws_ecr_repository" "repository_1" {
  name                 = "${var.tags_owner}-${var.tags_env}-repository-1"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
