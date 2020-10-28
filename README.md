# terraform_aws_v2
[ terraform apply ] と実行するだけで AWS の各リソース（vpc/subnet/s3/ec2/rds/...etc）を自動的に構築することが可能です。<br>
現在は以下のバージョンで作成しています。
| provider  | verion   |
| --------- | -------- |
| terraform | 0.13.5 |
| aws       | 3.12.0 |

# はじめにやっておくこと
コマンド実行前に、以下のことが必要です。<br>
1. 下記URL より terraform.exe をダウンロード<br>
    https://www.terraform.io/downloads.html<br>
    ※ Windows であれば、terraform.exe をダウンロードして PATH を通すだけです。<br>

2. terraform.exe を適当な場所へ配置してパスを通す<br>
    https://qiita.com/miwato/items/b7e66cb087666c3f9583<br>
    https://dev.classmethod.jp/articles/try-terraform-on-windows/<br>
    https://proengineer.internous.co.jp/content/columnfeature/5205<br>

3. ~/.aws/credentials<br>
    空のファイル C:¥user¥.aws¥credentials を作成してください。<br>

4. AWS アクセスキー情報を ~/.aws/credentials に入力してください。
    [default]
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"<br>
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"<br>


# module vpc
vpc は基本５個までしか作成できません。<br>
cidr を効率よく使い、複数人で vpc を共有するよう設計されています。<br>
route_table はユーザー間で共有しないため、互いのネットワーク間の干渉は避けられます。
