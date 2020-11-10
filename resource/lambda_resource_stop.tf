#
# 参考：https://dev.classmethod.jp/articles/terraform-lambda-deployment/
#      https://qiita.com/ktsujichan/items/c0804f155c2cf1962ed3
# 
# ソースの準備方法
#   1. build/function/src 配下に python3.8 実行プログラム配置
#   2. パッケージ取得
#       cd resource
#       python3 -m pip install boto3 -t build/layer/python
#       python3 -m pip install datetime -t build/layer/python
#   3. 圧縮
#       build/function/src --> build/function/src.zip
#       build/layer/python --> build/layer/python.zip
#   4. 配置
#       build/function/src.zip --> build/lambda/src.zip
#       build/layer/python.zip --> build/lambda/python.zip

# Layer
resource "aws_lambda_layer_version" "resource_stop" {
  layer_name       = "${var.tags_owner}-${var.tags_env}-resource-stop"
  filename         = var.layer_zip
  source_code_hash = filebase64sha256(var.layer_zip)
}

# Function
resource "aws_lambda_function" "resource_stop" {
  function_name = "${var.tags_owner}-${var.tags_env}-resource-stop"

  handler          = "src/resource_stop.lambda_handler"
  filename         = var.function_zip
  runtime          = "python3.8"
  publish          = true
  timeout          = 10
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.resource_stop.arn]
  source_code_hash = filebase64sha256(var.function_zip)

  environment {
    variables = {
      tags_owner = var.tags_owner
      tags_env   = var.tags_env
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
