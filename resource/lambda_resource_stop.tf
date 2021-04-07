#
# 参考：https://dev.classmethod.jp/articles/terraform-lambda-deployment/
#      https://qiita.com/ktsujichan/items/c0804f155c2cf1962ed3
# 
# ソースの準備方法
#   1. build/resource_stop/function/src 配下に python3.8 実行プログラム配置
#   2. ディレクトリ（resource）に移動
#       cd ~/.../resource
#   3. python ライブラリ保存用ディレクトリ作成
#       mkdir -p build/resource_stop/layer/python
#   4. ライブラリのインストール
#       python3 -m pip install boto3    -t build/resource_stop/layer/python
#       python3 -m pip install datetime -t build/resource_stop/layer/python
#   5. キャッシュ系ファイルの削除（不要な差分回避のため）
#       find build -type f | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm
#

/*
# Archive
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "../../build/resource_stop/layer"
  output_path = "../../build/resource_stop/layer.zip"
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../../build/resource_stop/function"
  output_path = "../../build/resource_stop/function.zip"
}
*/

# Layer
resource "aws_lambda_layer_version" "resource_stop" {
  layer_name       = "${var.tags_owner}-${var.tags_env}-resource-stop"
  
  # Archive
  # filename         = data.archive_file.layer_zip.output_path
  # source_code_hash = filebase64sha256(data.archive_file.layer_zip.output_path)

  # Use prepared zips
  filename         = var.layer_zip
  source_code_hash = filebase64sha256(var.layer_zip)

  # ソースコードのハッシュ値で変更の有無を判断するため、日付は無視する
  lifecycle {
    ignore_changes = [
      created_date
    ]
  }
}

# Function
resource "aws_lambda_function" "resource_stop" {
  function_name = "${var.tags_owner}-${var.tags_env}-resource-stop"
  handler          = "src/resource_stop.lambda_handler"

  # Archive
  # filename         = data.archive_file.function_zip.output_path
  # source_code_hash = filebase64sha256(data.archive_file.function_zip.output_path)

  # Use prepared zips
  filename         = var.resource_stop_zip
  source_code_hash = filebase64sha256(var.resource_stop_zip)

  runtime          = "python3.8"
  publish          = true
  timeout          = 10
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.resource_stop.arn]
  # ソースコードのハッシュ値で変更の有無を判断するため、日付は無視する
  lifecycle {
    ignore_changes = [
      last_modified
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

# resource_stop schedule
resource "aws_cloudwatch_event_rule" "resource_stop" {
  name                = "${var.tags_owner}-${var.tags_env}-resource-stop"
  description         = "resource stop schedule"
  schedule_expression = "cron(0 * * * ? *)" # UTC
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
  role_arn  = ""
  input     = "{}"
}