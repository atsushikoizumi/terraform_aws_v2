# event schedule
resource "aws_cloudwatch_event_rule" "resource_stop" {
  name                = "${var.tags_owner}-${var.tags_env}-resource-stop"
  description         = "resource stop schedule"
  schedule_expression = "cron(0 * * * ? *)"
  is_enabled          = var.resource_stop_flag
    tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_cloudwatch_event_target" "resource_stop" {
  rule      = aws_cloudwatch_event_rule.resource_stop.name
  target_id = "${var.tags_owner}-${var.tags_env}-resource-stop"
  arn       = aws_lambda_function.resource_stop.arn
}
