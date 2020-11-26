# Function
resource "aws_lambda_function" "resource_start" {
  function_name = "${var.tags_owner}-${var.tags_env}-resource-start"

  handler          = "src/resource_start.lambda_handler"
  filename         = "..\\..\\build\\resource_start\\function.zip"
  runtime          = "python3.8"
  publish          = true
  timeout          = 10
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.resource_stop.arn]
  source_code_hash = filebase64sha256("..\\..\\build\\resource_start\\function.zip")
  lifecycle {
    ignore_changes = [
      last_modified,filename
    ]
  }
  environment {
    variables = {
      tags_owner   = var.tags_owner
      tags_env     = var.tags_env
      ec2_win_name = aws_instance.ec2_win2019.tags.Name
      ec2_amzn_nam = aws_instance.ec2_amzn2.tags.Name
    }
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }

}

resource "aws_lambda_permission" "resource_start" {
  statement_id  = "${var.tags_owner}-${var.tags_env}-resource-start"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_start.arn
}
