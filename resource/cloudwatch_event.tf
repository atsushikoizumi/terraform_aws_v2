# resource_stop schedule
resource "aws_cloudwatch_event_rule" "resource_stop" {
  name                = "${var.tags_owner}-${var.tags_env}-resource-stop"
  description         = "resource stop schedule"
  schedule_expression = "cron(0 */2 * * ? *)"  # UTC
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
  role_arn = ""
  input = "{}"
}

# resource_start schedule
resource "aws_cloudwatch_event_rule" "resource_start" {
  name                = "${var.tags_owner}-${var.tags_env}-resource-start"
  description         = "resource start schedule"
  schedule_expression = "cron(30 16 * * ? *)"  # UTC
  is_enabled          = var.logical_backup_flag
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_cloudwatch_event_target" "resource_start" {
  rule      = aws_cloudwatch_event_rule.resource_start.name
  target_id = "${var.tags_owner}-${var.tags_env}-resource-start"
  arn       = aws_lambda_function.resource_start.arn
  role_arn = ""
  input = "{}"
}

# logicalbackup schedule
resource "aws_cloudwatch_event_rule" "logicalbackup" {
  name                = "${var.tags_owner}-${var.tags_env}-logicalbackup"
  description         = "rds logicalbackup schedule"
  schedule_expression = "cron(30 17 * * ? *)"  # UTC
  is_enabled          = var.logical_backup_flag
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_cloudwatch_event_target" "logicalbackup" {
  rule = aws_cloudwatch_event_rule.logicalbackup.name
  target_id = "${var.tags_owner}-${var.tags_env}-logicalbackup-task"
  arn = aws_ecs_cluster.logicalbackup.arn
  role_arn = aws_iam_role.cloudwatch_events_role.arn
  input = "{}"

  ecs_target {
    task_count = 1
    task_definition_arn = aws_ecs_task_definition.logicalbackup.arn
    launch_type = "FARGATE"
    platform_version = "1.4.0"  # 1.4 ではなく、 1.4.0 と指定しないと動かない

    network_configuration {
      assign_public_ip = true
      security_groups = [aws_security_group.ec2.id]
      subnets = [aws_subnet.ec2["eu-north-1a"].id]
    }
  }
  
}
