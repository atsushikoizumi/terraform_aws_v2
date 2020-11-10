#
# サブネットの割当　以外は変更不要
#

# サブネットの割当（管理番号により値を変更）
variable "ec2_subnet" {
  default = {
    "eu-north-1a" = "10" # subnet id に応じて変更
    "eu-north-1b" = "11" # subnet id に応じて変更
    "eu-north-1c" = "12" # subnet id に応じて変更
  }
}
variable "rds_subnet" {
  default = {
    "eu-north-1a" = "13" # subnet id に応じて変更
    "eu-north-1b" = "14" # subnet id に応じて変更
    "eu-north-1c" = "15" # subnet id に応じて変更
  }
}
variable "redshift_subnet" {
  default = {
    "eu-north-1a" = "16" # subnet id に応じて変更
    "eu-north-1b" = "17" # subnet id に応じて変更
    "eu-north-1c" = "18" # subnet id に応じて変更
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

