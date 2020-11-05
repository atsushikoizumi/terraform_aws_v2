#
# 参考：https://dev.classmethod.jp/articles/terraform-lambda-deployment/
#      https://qiita.com/ktsujichan/items/c0804f155c2cf1962ed3
# 
# ソースの準備方法
#   1. build/function/src 配下に python3.8 実行プログラム配置
#   2. python3 -m pip install boto3 -t build/layer/python  パッケージ取得
#   3. build/function --> lambda/function.zip
#   4. build/layer/python --> lambda/python.zip
#

# Layer
resource "aws_lambda_layer_version" "rds_stop" {
  layer_name       = "${var.tags_owner}-${var.tags_env}-rds-stop"
  filename         = var.layer_zip
  source_code_hash = filebase64sha256(var.layer_zip)
}

# Function
resource "aws_lambda_function" "rds_stop" {
  function_name = "${var.tags_owner}-${var.tags_env}-rds-stop"

  handler          = "src/rds_stop.lambda_handler"
  filename         = var.function_zip
  runtime          = "python3.8"
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.rds_stop.arn]
  source_code_hash = filebase64sha256(var.function_zip)

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