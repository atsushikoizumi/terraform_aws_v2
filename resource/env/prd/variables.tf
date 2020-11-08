#
# サブネットの割当　以外は変更不要
#

# サブネットの割当（管理番号により値を変更）
variable "ec2_subnet" {
  default = {
    "eu-north-1a" = "30" # subnet id に応じて変更
    "eu-north-1b" = "31" # subnet id に応じて変更
    "eu-north-1c" = "32" # subnet id に応じて変更
  }
}
variable "rds_subnet" {
  default = {
    "eu-north-1a" = "33" # subnet id に応じて変更
    "eu-north-1b" = "34" # subnet id に応じて変更
    "eu-north-1c" = "35" # subnet id に応じて変更
  }
}
variable "redshift_subnet" {
  default = {
    "eu-north-1a" = "36" # subnet id に応じて変更
    "eu-north-1b" = "37" # subnet id に応じて変更
    "eu-north-1c" = "38" # subnet id に応じて変更
  }
}

# lambda ソース
variable "layer_zip" {
  default = "../../build/lambda/python.zip"
}
variable "function_zip" {
  default = "../../build/lambda/src.zip"
}

# 個人設定用
variable allow_ip {}
variable resource_stop_flag {}
variable tags_owner {}
variable tags_env {}
variable public_key_path {}
variable private_key_path {}
variable git_account {}
variable git_pass {}

