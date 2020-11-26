# logicalbackup
resource "aws_ecs_cluster" "logicalbackup" {
  name = "${var.tags_owner}-${var.tags_env}-logicalbackup"
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}