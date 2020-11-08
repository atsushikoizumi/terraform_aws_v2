# タグ名
variable tags_owner {
  default = "koizumi"
}
variable tags_env {
  default = "stg"
}

# アクセスを許可する ip アドレス
variable allow_ip {
  default = ["114.156.135.182/32", "60.104.132.36/32", "126.247.81.226/32"]
  # aqua 114.156.135.182/32
  # home 60.104.132.36/32
  # iphone 126.247.81.226
  # all ip address [0.0.0.0]
}

# 1時間毎に RDS/Redshift を停止する lambda が動きます。
# RDS/Redshift を使用するときは、本設定を false に変更してください。
variable resource_stop_flag {
  default = true
}

# ssh キーペアーのパブリックキー
variable public_key_path {
  default = "/Users/atsushi/.ssh/aws_work.pub" # 相対パス、フルパスの指定も可能
  # (windows) c:\\Users\\atsus\\.ssh\\aws_work.pub
  # (mac) /Users/atsushi/.ssh/aws_work.pub
}

# github
variable git_account {
  default = "atsushi.koizumi@aqua-systems.co.jp"
}
variable git_pass {
  default = "Aqua_go_112!"
}

# サブネットの割当（管理番号により値を変更）
# 管理番号 1 = (10,11,12,13....18)  # 管理番号 2 = (20,21,22,23....28)
variable "ec2_subnet" {
  default = {
    "eu-north-1a" = "20" # 管理番号 20 -> "eu-west-1a"  = "20" 
    "eu-north-1b" = "21" # 管理番号 20 -> "eu-west-1b"  = "21"
    "eu-north-1c" = "22" # 管理番号 20 -> "eu-west-1c"  = "22"
  }
}
variable "rds_subnet" {
  default = {
    "eu-north-1a" = "23" # 管理番号 20 -> "eu-west-1a"  = "23" 
    "eu-north-1b" = "24" # 管理番号 20 -> "eu-west-1a"  = "24" 
    "eu-north-1c" = "25" # 管理番号 20 -> "eu-west-1a"  = "25" 
  }
}
variable "redshift_subnet" {
  default = {
    "eu-north-1a" = "26" # 管理番号 20 -> "eu-west-1a"  = "26" 
    "eu-north-1b" = "27" # 管理番号 20 -> "eu-west-1a"  = "27" 
    "eu-north-1c" = "28" # 管理番号 20 -> "eu-west-1a"  = "28" 
  }
}

# lambda ソース
variable "layer_zip" {
  default = "../../build/lambda/python.zip"
}

variable "function_zip" {
  default = "../../build/lambda/src.zip"
}