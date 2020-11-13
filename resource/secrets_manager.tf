#
# [point]
# secret name は bash で参照する場合、ハイフンは変数として正しく認識されない。
# アンダーバーにしておくのが無難。
#
resource "aws_secretsmanager_secret" "dbpassword" {
  name                    = "${var.tags_owner}_${var.tags_env}_DBPASSWORD"
  recovery_window_in_days = 7
  description             = "rds aurora logical backup"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_secretsmanager_secret_version" "dbpassword" {
  secret_id     = aws_secretsmanager_secret.dbpassword.id
  secret_string = jsonencode(var.db_master_password)
}
