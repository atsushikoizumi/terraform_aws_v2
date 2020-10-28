# terraform_aws_v2
terraform apply とコマンド実行するだけで AWS の各リソース（vpc/subnet/s3/ec2/rds/...etc）を自動的に構築することが可能です。現在は以下のバージョンに対応しています。
| provider  | verion   |
| --------- | -------- |
| terraform | 0.13.5 |
| aws       | 3.12.0 |

# はじめにやっておくこと
コマンド実行前に、以下のことが必要です。
1. terraform.exe を取得

    下記URL より terraform.exe をダウンロード<br>
    https://www.terraform.io/downloads.html<br>
    ※ Windows であれば、terraform.exe をダウンロードして PATH を通すだけです。

2. terraform.exe へ PATH を通す。

    PATH の通し方がわからない場合は、以下のURL等を参考にしてください。<br>
    https://qiita.com/miwato/items/b7e66cb087666c3f9583<br>
    https://dev.classmethod.jp/articles/try-terraform-on-windows/<br>
    https://proengineer.internous.co.jp/content/columnfeature/5205

3. ~/.aws/credentials 作成

    空のファイル C:¥user¥.aws¥credentials を作成してください。

4. AWS アクセスキー情報登録

    ~/.aws/credentials に以下の内容を入力してください。<br>
    profile 名は自身のものに置き換えてください。
    ```
    [koizumi]
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    ```

5. s3 バケット作成
    terraform は .tfstate というファイルで resource の状態を保持します。<br>
    セキュリティや運用の観点からローカルに保存するのではなく、s3 に置くことが推奨されています。<br>
    事前に s3 に置き場所を用意しておく必要があります。
    | key | value |
    | --------- | -------- |
    | region | eu-west-1 |
    | backet name | aws-aqua-terraform |
    | prefix | username |

以下、module の説明を記載します。

# module vpc
vpc は社内で共有します。理由は各リージョン基本５個までしか vpc は作成できないからです。<br>
そのため、cidr を効率よく使い、複数人で vpc を共有できるよう設計しています。<br>
route_table はユーザー間で共有しないため、お互いのネットワーク間の干渉は避けられます。
S