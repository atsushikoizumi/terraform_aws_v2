# module resource/env/dev
AWS の環境情報を管理する module です。<br>
使用方法について記載します。

1. main.tf を編集

    以下を全て自身のものに編集します。ただし、変更不可を除く。
    ```
    # Terraform
    terraform {
    backend "s3" {
        region                  = "eu-west-1"
        bucket                  = "aws-aqua-terraform"
        key                     = "koizumi/dba-test/resource_dev.tfstate"
        shared_credentials_file = "~/.aws/credentials"
        profile                 = "koizumi"
    }
    required_version = "0.13.5"  ※変更不可
    }

    # Provider
    provider "aws" {
    region                  = "eu-north-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "koizumi"
    version                 = "3.12.0"  ※変更不可
    }

    # get vpc remote state
    data "terraform_remote_state" "vpc" {
    backend = "s3"

    config = {
        region                  = "eu-west-1"  ※変更不可
        bucket                  = "aws-aqua-terraform"  ※変更不可
        key                     = "koizumi/dba-test/vpc.tfstate"  ※変更不可
        shared_credentials_file = "~/.aws/credentials"
        profile                 = "koizumi"

    }
    ```

2. variables.tf を編集

    編集する項目は以下です。
    ```
    ec2_subnet      : 割り当てられたサブネット番号を指定ください。
    rds_subnet      : 割り当てられたサブネット番号を指定ください。
    redshift_subnet : 割り当てられたサブネット番号を指定ください。
    ```

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
    private_key_path    : パブリックキーのパスを指定ください。
    git_account         : github のアカウントをしてください。
    git_pass            : github のアカウントパスワードをしてください。
    db_master_password  : 各リソースのユーザーパスワードを指定ください。
    logical_backup_flag : true or false を指定ください。
    ```

4. リソースの作成開始
    以下の手順でリソースの作成を実行してください。
    ```
    $ cd /User/.../resource/env/dev
    $ terraform init       # .tfstate 準備
    $ terraform apply      # 環境構築
    $ terraform output     # 接続情報取得
    ```

5. リソースへのアクセス
    上記で取得した接続情報をもとに、リソースへアクセスが可能です。<br>
    接続のユーザー名とパスワードは以下です。
    | ec2         | 初期ユーザー     | パスワード                                    |
    | ----------- | -------------- | ------------------------------------------- |
    | ec2_amzn2   | ${tags_owner}  | なし                                         |
    | ec2_win2019 | ${tags_owner}  | db_master_password の windows2019 で指定した値 |
    ※デフォルトの ec2-user は削除しています。
    ※初期ユーザーに sudo権限、Adminidtrator権限を付与していますので問題なく操作できます。

9. 備考<br>
タグ名（owner_tag,tags_env）によってリソースを管理しています。<br>
owner_tag と tags_env が同一のリソースを複数作成することはできません。
