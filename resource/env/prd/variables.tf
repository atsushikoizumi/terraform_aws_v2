# タグ名
variable tags_owner {
  default = "koizumi"
}
variable tags_env {
  default = "prd"
}

# アクセスを許可する ip アドレス
variable allow_ip {
  default = ["114.156.135.182/32", "60.104.132.36/32"]
  # aqua 114.156.135.182
  # home 60.104.132.36
  # all ip address [0.0.0.0]
}

# ssh キーペアーのパブリックキー
variable public_key_path {
  default = "/Users/atsushi/.ssh/aws_work.pub"   # 相対パス、フルパスの指定も可能
  # (windows) c:\\Users\\atsus\\.ssh\\aws_work.pub
  # (mac) /Users/atsushi/.ssh/aws_work.pub
}

# サブネットの割当（管理番号により値を変更）
# 管理番号 1 = (10,11,12,13....18)  # 管理番号 2 = (20,21,22,23....28)
variable "ec2_subnet"{
  default = {
      "eu-north-1a"  = "30"         # 管理番号 20 -> "eu-west-1a"  = "20" 
      "eu-north-1b"  = "31"         # 管理番号 20 -> "eu-west-1b"  = "21"
      "eu-north-1c"  = "32"         # 管理番号 20 -> "eu-west-1c"  = "22"
  }
}
variable "rds_subnet"{
  default = {
      "eu-north-1a"  = "33"         # 管理番号 20 -> "eu-west-1a"  = "23" 
      "eu-north-1b"  = "34"         # 管理番号 20 -> "eu-west-1a"  = "24" 
      "eu-north-1c"  = "35"         # 管理番号 20 -> "eu-west-1a"  = "25" 
  }
}
variable "redshift_subnet"{
  default = {
      "eu-north-1a"  = "36"         # 管理番号 20 -> "eu-west-1a"  = "26" 
      "eu-north-1b"  = "37"         # 管理番号 20 -> "eu-west-1a"  = "27" 
      "eu-north-1c"  = "38"         # 管理番号 20 -> "eu-west-1a"  = "28" 
  }
}
