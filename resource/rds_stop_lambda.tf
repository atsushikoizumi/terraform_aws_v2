#
# 参考：https://dev.classmethod.jp/articles/terraform-lambda-deployment/
#      https://qiita.com/ktsujichan/items/c0804f155c2cf1962ed3
#
# python -m pip install datetime -t build/layer/python
# python -m pip install boto3 -t build/layer/python
# find build -type f | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm
#


# Archive
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "../../build/layer"
  output_path = "../../lambda/layer.zip"
}
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../../build/function"
  output_path = "../../lambda/function.zip"
}

# Layer
resource "aws_lambda_layer_version" "rds_stop" {
  layer_name       = "${var.tags_owner}-${var.tags_env}-rds-stop"
  filename         = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
}

# Function
resource "aws_lambda_function" "rds_stop" {
  function_name = "${var.tags_owner}-${var.tags_env}-rds-stop"

  handler          = "src/rds_stop.lambda_handler"
  filename         = data.archive_file.function_zip.output_path
  runtime          = "python3.8"
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.rds_stop.arn]
  source_code_hash = data.archive_file.function_zip.output_base64sha256

  environment {
    variables = {
      tags_owner = var.tags_owner
      tags_env   = var.tags_env
    }
  }
}

# event schedule
resource "aws_cloudwatch_event_rule" "rds_stop" {
  name                = "${var.tags_owner}-${var.tags_env}-rds-stop"
  description         = "rds stop schedule"
  schedule_expression = "cron(0 * * * ? *)"
  is_enabled          = var.rds_stop_flag
}

resource "aws_cloudwatch_event_target" "rds_stop" {
  rule      = aws_cloudwatch_event_rule.rds_stop.name
  target_id = "rds_stop"
  arn       = aws_lambda_function.rds_stop.arn
}

resource "aws_lambda_permission" "rds_stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_stop.arn
}