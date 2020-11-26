# terraform_aws_v2

![terraform_aws_v2](https://github.com/atsushikoizumi/terraform_aws_v2/blob/main/aws_terraform_v2.jpg)<br>

以下のコマンド実行するだけで AWS の各リソース（vpc/subnet/s3/ec2/rds/...etc）を自動的に構築することが可能です。<br>
さらに、コンソール画面を一度も見ることなくリソースへのアクセスも可能です。
```
$ cd /User/.../resource/env/dev
$ terraform init       # .tfstate 準備
$ terraform apply      # 環境構築
$ terraform output     # 接続情報取得
```
現在は以下のバージョンに対応しています。
| provider  | version                   |
| --------- | ------------------------- |
| terraform | 0.13.5                    |
| aws       | 3.12.0                    |
| python    | 3.8.6                     |

# 利用タグ一覧
利用タグ（Owner/Env）の組み合わせ毎にサブネットを割り当てています。<br>
| No | Owner    | Env | subnet id |
| -- | -------- | --- | --------- |
| 1  | koizumi  | dev | 10 - 19   |
| 2  | koizumi  | stg | 20 - 29   |
| 3  | koizumi  | prd | 30 - 39   |

# 前提
事前に以下の設定を実施する必要があります。
```
  1. terraform.exe をダウンロード、PATH を通す。

    https://www.terraform.io/downloads.html


  2. python3系(3.8)のインストール

    インストール手順はネットで調べてください。

  3. credentials作成

    空のファイル C:¥user¥.aws¥credentials を作成し、以下の内容を入力してください。

    [sample]  >> 自身のものに置き換えてください。
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

  4. s3バケット作成

    terraform は .tfstate というファイルでリソースの状態を保持します。
    セキュリティや運用の観点からローカルに保存するのではなく、s3 に置くことが推奨されています。
    事前に保管用の s3 を用意してください。

```

# module vpc
vpc を管理する module です。この module は変更しないでください。<br>
全環境で vpc は共有しています。

# module resource
AWS の各リソースを作成するための module です。<br>
各リソースの細かいパラメーターを変更する際は、この module 配下の .tf ファイルを編集してください。<br>
また、lambda で使用するソースのレイヤーを作成するため、python のライブラリをインストールします。<br>
python のライブラリインストール手順の詳細は resource 階層の README を参照ください。

# module resource/env/dev
環境情報をこの module で管理しています。<br>
terraform apply 実行前に、resource/env/dev 配下の環境設定ファイル（main.tf/variable.tf）を編集します。<br>
詳細は、resource/env/dev 階層にある README を参照ください。

# module resource/env/stg
ステージング環境用で使用するモジュールです。

# module resource/env/prd
本番環境用で使用するモジュールです。<br>
<br>
以上です。
