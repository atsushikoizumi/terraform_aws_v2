#
# 個人設定
#

# 1. タグ名
#    タグ名はサブネット名、セキュリティグループ名、リソース名などにも利用されます。
#    そのため、途中で変更するとリソースの再作成が実施されますので、途中変更はお勧めしません。
tags_owner = "sample"
tags_env   = "test"


# 2. 有料リソース停止フラグ
#    1時間毎に WinServer/RDS/Redshift を停止する lambda が動きます。
#    リソースを使用するときは、本設定を false に変更し terraform apply を実行してください。
#    リソースを使用しないときは、本設定を true に変更し terraform apply を実行してください。
#    true or false
resource_stop_flag = true


# 3. アクセス許可 ip アドレス
#    ec2/ecs にアクセスを許可する ip address を指定することができます。
#    基本的には、会社と自宅の ip address のみを指定することを推奨します。
#    ポケットwifiを使用している場合、アクセスの都度 ip address が変動する場合があります。
#    その場合は、都度、接続元の ip address を記述し、terraform apply を実行してください。
#    以下のように全ての ip address からの接続を許可することもできますが、推奨しません。
#    allow_ip = [0.0.0.0/0]
allow_ip = ["111.111.111.111/32", "222.222.222.222/32"]


# 4. ssh key
#    SSHキーを自分で作成し保管してください。
#    パスの指定方法は絶対パス、相対パスどちらも設定可能です。
#
#    4-1. 絶対パス
#      (windows) c:\\Users\\user\\.ssh\\public_key
#      (mac)     /Users/user/.ssh/public_key
#      (linux)   /home/user/.ssh/public_key
#    4-2. 相対パス（terraform apply を実行するパスから見て）
#      (any)     ./public_key
#
public_key_path  = "/Users/user/.ssh/public_key"
private_key_path = "/Users/user/.ssh/private_key"


# 5. github
#    自身の github アカウントを指定してください。
#    ec2_amzn2 のリソース作成時に、アクアラボの各種 repository を自動で ec2-user に clone します。
#    本設定は行わなくてもリソースの作成は問題なく行われます。（git clone コマンドが失敗しますが無視されます。）
git_account = "xxxxxx"
git_pass    = "xxxxxx"
