# 環境情報の設定
terraformを実行するために環境情報を設定します。<br>

1. main.tf を編集

    以下を編集します。
    ```
    # Terraform
    terraform {
    backend "s3" {
        region                  = "eu-west-1"                # 準備したバケットのリージョンを指定
        bucket                  = "aws-aqua-terraform"       # 準備したバケットを指定
        key                     = "xxxxxx/resource.tfstate"  # ファイルのパスを指定
        shared_credentials_file = "~/.aws/credentials"
        profile                 = "sample"                   # profile名
    }
    required_version = "0.13.5"
    }

    # Provider
    provider "aws" {
    region                  = "eu-north-1"                   # 変更不可
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "sample"                       # profile名
    version                 = "3.12.0"
    }
    ```

2. variables.tf を編集

    以下の "xx" を割り当てられた subnet id に変更してください。
    ```
    # サブネットの割当（管理番号により値を変更）
    variable "ec2_subnet" {
    default = {
        "eu-north-1a" = "xx"
        "eu-north-1b" = "xx"
        "eu-north-1c" = "xx"
    }
    }
    variable "rds_subnet" {
    default = {
        "eu-north-1a" = "xx"
        "eu-north-1b" = "xx"
        "eu-north-1c" = "xx"
    }
    }
    variable "redshift_subnet" {
    default = {
        "eu-north-1a" = "xx"
        "eu-north-1b" = "xx"
        "eu-north-1c" = "xx"
    }
    }
    ```
    subnet id の割り当ては以下です。
    | No | Owner    | Env | subnet id |
    | -- | -------- | --- | --------- |
    | 1  | koizumi  | dev | 10 - 19   |
    | 2  | koizumi  | stg | 20 - 29   |
    | 3  | natsume  | dev | 30 - 39   |
    | 4  | horihory | dev | 40 - 49   |

    （例）Owner=koizumi,Env=stg では、20,21,22,23,24,25,26,27,28,29 の subnet id が使用可能です。

3. sample.tfvars を編集

    以下の通りファイル名を変更してください。
    ```
    sample.tfvars  -->  terraform.tfvars
    ```
    ファイル内の編集する項目は以下です。
    ```
    tags_owner          : 利用者名を指定ください。
    tags_env            : 環境を表す任意の単語を指定ください。
    resource_stop_flag  : true or false を指定ください。
    allow_ip            : 踏み台サーバーにアクセスを許可するip（配列形式）を指定ください。
    public_key_path     : パブリックキーのパスを指定ください。 
    private_key_path    : プライベートキーのパスを指定ください。
    git_account         : github のアカウントをしてください。
    git_pass            : github のアカウントパスワードをしてください。
    db_master_password  : 各リソースのユーザーパスワードを指定ください。
    logical_backup_flag : true or false を指定ください。
    ```

# 環境構築
以下の手順で環境を構築し、踏み台サーバーへアクセスします。

1. 環境構築

    以下の手順でリソースの作成を実行してください。<br>
    コマンドの実行場所は、自身のフォルダ直下を前提としています。
    ```
    $ terraform init       # 準備
    $ terraform apply      # 環境構築
    ```
    terraform apply の実行結果に接続情報が出力されるよう作ってあります。

2. 踏み台サーバーへのアクセス

    接続ユーザーとパスワードは以下です。
    | os            | user        | password                        |
    | ------------- | ----------- | ------------------------------- |
    | AmazonLinux2  | tags_owner  |                                 |
    | WinServer2019 | tags_owner  | terraform.tfvars で設定した値（db_master_password,key=windows2019） |

    ※AmazonLinux2 ではデフォルトの ec2-user は削除しています。<br>
    ※WinServer2019 では SSH－Key でのパスワード取得は不要です。user でログインできます。<br>
    ※WinServer2019 のキーボード設定がデフォルト日本語ではないです。<br>
    ※初期ユーザー（user）に sudo 権限、Adminidtrator 権限を付与しています。

3. ec2 の設定情報

    デフォルトで以下の設定を行なっています。
    | os            | setting     |
    | ------------- | ----------- |
    | AmazonLinux2  | 日本語設定、日本時間設定 |
    |               | awscli,curl,unzip,jq,mysql,psql,sqlplus,sqlcmd,git,docker,python3.8,amazon-efs-utils |
    |               | Aqua-Lab. の各種 repositpry を ~/github 配下に clone |
    |               | efs が ~/efs にマウント |
    | WinServer2019 | "C:\applications" によく使用するアプリケーション（exe）を配置 |

4. rds の設定情報

    resource の階層にある rds/redshift の .tf ファイルを参照ください。
