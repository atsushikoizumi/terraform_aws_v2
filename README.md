# terraform_aws_v2
[ terraform apply ] と実行するだけで AWS の各リソース（vpc/subnet/s3/ec2/rds/...etc）を自動的に構築することが可能です。現在は以下のバージョンに対応しています。
| provider  | verion   |
| --------- | -------- |
| terraform | 0.13.5 |
| aws       | 3.12.0 |

# はじめにやっておくこと
コマンド実行前に、以下のことが必要です。
1. 下記URL より terraform.exe をダウンロード

    https://www.terraform.io/downloads.html<br>
    ※ Windows であれば、terraform.exe をダウンロードして PATH を通すだけです。<br>

2. terraform.exe を適当な場所へ配置してパスを通す

    https://qiita.com/miwato/items/b7e66cb087666c3f9583<br>
    https://dev.classmethod.jp/articles/try-terraform-on-windows/<br>
    https://proengineer.internous.co.jp/content/columnfeature/5205<br>

3. ~/.aws/credentials

    空のファイル C:¥user¥.aws¥credentials を作成してください。<br>

4. AWS アクセスキー情報を ~/.aws/credentials に入力してください。

    [default]
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"<br>
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"<br>

以下、module の説明を記載します。

# module vpc
vpc は社内で共有します。理由は各リージョン基本５個までしか vpc は作成できないからです。<br>
そのため、cidr を効率よく使い、複数人で vpc を共有できるよう設計しています。<br>
    route_table はユーザー間で共有しないため、お互いのネットワーク間の干渉は避けられます。
