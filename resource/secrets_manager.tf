#
# [point]
# secret name は bash で参照する場合、ハイフンは変数として正しく認識されない。
# アンダーバーにしておくのが無難。
#
resource "aws_secretsmanager_secret" "aurora_pass" {
  name = "${var.tags_owner}_${var.tags_env}_aurora_pass"
  recovery_window_in_days = 7
  description = "rds aurora logical backup"
    tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

variable "aurora_pass" {
  default = {
    "postgresql" = "Admin123!"
    "mysql" = "Admin123!"
  }

  type = map(string)
}

resource "aws_secretsmanager_secret_version" "aurora_pass" {
  secret_id     = aws_secretsmanager_secret.aurora_pass.id
  secret_string = jsonencode(var.aurora_pass)
}
