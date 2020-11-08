# module resource/env/dev
AWS の環境情報を管理する module です。<br>
使用方法について記載します。

1. main.tf を編集

    Terraform は以下のうように編集します。
    ```
    terraform {
        backend "s3" {
            region                  = ".tfstate を保存するリージョン"
            bucket                  = ".tfstate を保存するバケット名"
            key                     = ".tfstate を保存するファイルパス名（ファイル名含む）"
            shared_credentials_file = "~/.aws/credentials"
            profile                 = "自分のプロファイル名"
        }
        required_version = "0.13.5"  ※変更不可
    }
    ```
    Provider は以下のように修正します。
    ```
    provider "aws" {
        region                  = "eu-north-1"  ※変更不可
        shared_credentials_file = "~/.aws/credentials"
        profile                 = "自分のプロファイル名"
        version                 = "3.12.0"  ※変更不可
    }
    ```
    terraform_remote_state は以下のように修正します。
    ```
    # 準備
    #    vpc.tfstate を s3 からローカル（/User/../resource/env/dev/）に保存します。
    #    vpc.tfstate は S3://aws-aqua-terraformkoizumi/dba-test/ にあります。
    #    aws cli なら以下のコマンドで取得できます。
    #    ex) aws s3 cp s3://aws-aqua-terraform/koizumi/dba-test/vpc.tfstate ./
    #
    # ローカルの vpc.tfstate を参照するよう修正します。
    data "terraform_remote_state" "vpc" {
        backend = "local"
        config = {
            path = "../resource/env/dev/vpc.tfstate"
        }
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
    tags_owner         : 利用者名を指定ください。
    tags_env           : 環境を表す任意の単語を指定ください。
    resource_stop_flag : true or false を指定ください。
    allow_ip           : 踏み台サーバーにアクセスを許可するip（配列形式）を指定ください。
    public_key_path    : パブリックキーのパスを指定ください。 
    private_key_path   : パブリックキーのパスを指定ください。
    git_account        : github のアカウントをしてください。
    git_pass           : github のアカウントパスワードをしてください。
    ```

9. 備考<br>
タグ名（owner_tag,tags_env）によってリソースを管理しています。<br>
owner_tag と tags_env が同一のリソースを複数作成することはできません。
