
resource "aws_secretsmanager_secret" "aurora_postgre_1st" {
  name = aws_rds_cluster.aurora_postgre_1st.cluster_identifier
  recovery_window_in_days = 7
    tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_secretsmanager_secret_version" "aurora_postgre_1st" {
  secret_id     = aws_secretsmanager_secret.aurora_postgre_1st.id
  secret_string = "xx_adm_pass"
}