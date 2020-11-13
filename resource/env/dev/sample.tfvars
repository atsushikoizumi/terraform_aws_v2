#
# 個人設定
#

# 1. タグ名
#    タグ名はサブネット名、セキュリティグループ名、リソース名などにも利用されます。
#    そのため、途中で変更するとリソースの再作成が実施されますので、途中変更はお勧めしません。
#
tags_owner = "sample"
tags_env   = "dev"


# 2. 有料リソース停止フラグ
#    1時間毎に WinServer/RDS/Redshift を停止する lambda が動きます。
#    リソースを使用するときは、本設定を false に変更し terraform apply を実行してください。
#    リソースを使用しないときは、本設定を true に変更し terraform apply を実行してください。
#    true or false
#
resource_stop_flag = false


# 3. アクセス許可 ip アドレス
#    ec2/ecs にアクセスを許可する ip address を指定することができます。
#    基本的には、会社と自宅の ip address のみを指定することを推奨します。
#    ポケットWiFiを使用している場合、アクセスの都度 ip address が変動する場合があります。
#    その場合は、都度、接続元の ip address を記述し、terraform apply を実行してください。
#    以下のように全ての ip address からの接続を許可することもできますが、推奨しません。
#    allow_ip = [0.0.0.0/0]
#
allow_ip = ["111.111.111.111/32", "222.222.222.222/32"]


# 4. ssh key
#    キーを自分で作成し保管してください。
#    パスの指定方法は絶対パス、相対パスどちらも設定可能です。
#
#    4-1. 絶対パス
#      (windows) C:\\Users\\user\\.ssh\\public_key
#      (mac)     /Users/user/.ssh/public_key
#      (linux)   /home/user/.ssh/public_key
#    4-2. 相対パス（terraform apply を実行するパスから見て）
#      (any)     ./public_key
#
public_key_path  = "/Users/user/.ssh/public_key"
private_key_path = "/Users/user/.ssh/private_key"


# 5. github
#    自身の github アカウントを指定してください。
#    ec2_amzn2 のリソース作成時に、アクアラボの各種 repository を自動で clone します。
#    本設定は行わなくてもリソースの作成は問題なく行われます。（git clone コマンドが失敗しますが無視されます。）
#
git_account = "xxxxxx@aaaaa.com"
git_pass    = "xxxxxx"


# 6. windows/rds/redshift password
#    各リソースのAdministrator/masteruserのパスワードは以下に設定してください。
#
db_master_password = {
  "windows2019" = "PassW0rd!"
  "postgresql"  = "PassW0rd!"
  "postgresql2" = "PassW0rd!"
  "mysql"       = "PassW0rd!"
  "mysql2"      = "PassW0rd!"
  "oracle"      = "PassW0rd!"
  "oracle2"     = "PassW0rd!"
  "sqlserver"   = "PassW0rd!"
  "sqlserver2"  = "PassW0rd!"
  "redshift2"   = "PassW0rd!"
}


# 7. RDS 論理バックアップ実行フラグ
#    毎日深夜の3時30分からDBの論理バックアップを取得します。
#    最新の自動バックアップから、インスタンスをリストアして論理バックアップを取得します。
#    準備として、fargate task で対象DB（DB_NAME）を指定します。
#    本設定は、defalut では false としています。 
#
#    [使用方法]
#    fargate task で 対象RDSインスタンス（****_1st）の DB_NAME を指定してください。
#    次に、本設定を true に変更し terraform apply を実行してください。
#    論理バックアップを使用しないときは、本設定を false に変更し terraform apply を実行してください。
#    true or false
#
logical_backup_flag = false
