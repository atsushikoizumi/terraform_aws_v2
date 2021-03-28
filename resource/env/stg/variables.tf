#
# サブネットの割当　以外は変更不要
#

# サブネットの割当（管理番号により値を変更）
variable "ec2_subnet" {
  default = {
    "eu-north-1a" = "20" # subnet id に応じて変更
    "eu-north-1b" = "21" # subnet id に応じて変更
    "eu-north-1c" = "22" # subnet id に応じて変更
  }
}
variable "rds_subnet" {
  default = {
    "eu-north-1a" = "23" # subnet id に応じて変更
    "eu-north-1b" = "24" # subnet id に応じて変更
    "eu-north-1c" = "25" # subnet id に応じて変更
  }
}
variable "redshift_subnet" {
  default = {
    "eu-north-1a" = "26" # subnet id に応じて変更
    "eu-north-1b" = "27" # subnet id に応じて変更
    "eu-north-1c" = "28" # subnet id に応じて変更
  }
}

# lambda ソース
variable "layer_zip" {
  default = "../../build/resource_stop/layer.zip"
}
variable "resource_stop_zip" {
  default = "../../build/resource_stop/function.zip"
}
variable "resource_start_zip" {
  default = "../../build/resource_start/function.zip"
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
variable db_master_password {
  type = map(string)
}
variable logical_backup_flag {}
