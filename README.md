# terraform_aws_v2

![terraform_aws_v2](https://github.com/atsushikoizumi/terraform_aws_v2/blob/main/aws_terraform_v2.jpg)<br>

以下のコマンド実行するだけで AWS の上記構成を構築することが可能です。<br>
```
$ terraform init
$ terraform apply
```
コマンドの実行後、コンソール画面を一度も見ることなくリソースへのアクセスも可能です。

# 対応バージョン
現在は以下のバージョンに対応しています。
| program      | version                   |
| ------------ | ------------------------- |
| terraform    | 0.13.5                    |
| aws provider | 3.12.0                    |
| python       | 3.8.6                     |

# 利用者一覧
利用タグ（Owner/Env）の組み合わせでリソースを識別しています。<br>
1人で複数環境を所持することが可能です。
| No | Owner     | Env | 
| -- | --------- | --- | 
| 1  | koizumi   | dev | 
| 2  | koizumi   | stg | 
| 3  | horihori  | dev | 

# 準備１
事前に以下の設定を実施する必要があります。
```
  1. "AquaLab" のラボメンになってください。
    小泉、安田、夏目までご連絡ください。
  
  2. Gitをインストールしてください。
    https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

  3. terraform.exe をダウンロードし、PATH を通してください。
    https://www.terraform.io/downloads.html

  4. credentialsを作成してください。
    C:\Users\xxxxx\.aws\credentials を作成し、以下の内容を入力してください。
    [sample]
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

  5. SSH-KEYを作成してください。
    SSH-KEY(private/public)を作成してください。
    $ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

  6. s3バケットを作成してください。
    terraform は .tfstate というファイルでリソースの状態を保持します。
    セキュリティや運用の観点からローカルに保存するのではなく、s3 に置くことが推奨されています。
    事前に保管用の s3 を用意してください。
```

# 準備２
以下の手順を実施してください。
```
  1. repositoryをcloneしてください。
    $ git clone https://github.com/aqua-labo/.....

  2. 自分用のフォルダを作成してください。
    \resource\env\sample を同階層にコピーしてフォルダ名を変更してください。

  3. 上記で作成したフォルダの直下にvpc.tfstateをダウンロードしてください。
    arn:aws:s3:::aws-aqua-terraform/koizumi/dba-test/vpc.tfstate
```

# 準備３
設定はまだ続きます。<br>
\resource\env\sampleのREADMEを参照してください。

