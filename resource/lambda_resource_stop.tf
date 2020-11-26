# Layer
resource "aws_lambda_layer_version" "resource_stop" {
  layer_name       = "${var.tags_owner}-${var.tags_env}-resource-stop"
  filename         = "..\\..\\build\\resource_stop\\layer.zip"
  source_code_hash = filebase64sha256("..\\..\\build\\resource_stop\\layer.zip")
  lifecycle {
    ignore_changes = [
      created_date,filename
    ]
  }
}

# Function
resource "aws_lambda_function" "resource_stop" {
  function_name = "${var.tags_owner}-${var.tags_env}-resource-stop"

  handler          = "src/resource_stop.lambda_handler"
  filename         = "..\\..\\build\\resource_stop\\function.zip"
  runtime          = "python3.8"
  publish          = true
  timeout          = 10
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.resource_stop.arn]
  source_code_hash = filebase64sha256("..\\..\\build\\resource_stop\\function.zip")
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

resource "aws_lambda_permission" "resource_stop" {
  statement_id  = "${var.tags_owner}-${var.tags_env}-resource-stop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_stop.arn
}
