#
# [Allways On AG 構築手順]
# https://aws.amazon.com/jp/premiumsupport/knowledge-center/ec2-windows-sql-server-always-on-cluster/
# https://qiita.com/zaburo/items/3468af8cd7d89b4c8bd5
#
##### Change Data Capture、および変更の追跡は、包含データベースではサポートされていません。 #####
#
# 1. ネットワーク設定
#      1-1. セカンダリIP付与
#      1-2. IPv4静的指定
#      1-3. DNSサフィックス指定
#      1-4. ファイアーウォール無効化
#
# 2. AD参加
#
# 3. クラスター作成（クラスターマネージャー）
#      3-1. [使用可能な記憶領域をすべてクラスターに追加] をオフ
#      3-2. セカンダリIPの1つ目を指定
#
# 4. SQLServerインストール（スタンドアローン）
#      4-1. プライマリ
#      4-2. セカンダリ（プライマリと同一名のフォルダ構成で作成） #DATA,LOG,BACKUP
#
# 5. データベース作成、テストデータ作成、完全バックアップ取得
#
# 6. ドメインアカウントにフォルダ共有、変更権限付与
#      6-1. DATA
#      6-2. LOG
#      6-3. BACKUP
#
# 7. 構成マネージャーの設定変更
#      7-1. TCP/IPを有効化
#      7-2. SQLServer(MSSQLSEVER)のログオンをドメインアカウントに変更
#      7-3. SQLServer(MSSQLSEVER)のAllwaysOnを有効化
#      7-4. サービス再起動
#
# 8. AG作成
#
# 9. リスナー作成
#      9-1. プライマリノード、セカンダリノード全てを追加
#      9-2. セカンダリIPの2つ目を指定
#
# 10. 包含データベースの設定（インスタンスレベルのアクセスが機能しないため）
#      10-1. サーバーレベル > プロパティ > 詳細設定 > 包含 > True
#      10-2. データベースレベル > プロパティ > オプション > 包含の種類 > 部分  ※排他処理
#
# 11. 接続テスト
#      11-1. PS> sqlcmd -S AVG01,1433 -U xx_apl1 -P Admin_123!! -d AVG01
#      11-2. SELECT @@SERVERNAME,@@SERVICENAME;
#      11-3. フェールオーバー
#      11-4. SELECT @@SERVERNAME,@@SERVICENAME;
#
#
#
# [DMS設定手順] SSMSでの操作
#
# 1. ディストリビューションの構成
#      1-1. 事前にSQLServerエージェントを自動起動に設定（構成マネージャー）
#      1-2. デフォルト設定で作成
#      1-3. リモートディストリビューションの場合はリモートパブリッシャーを追加
#
# 2. DMS設定 DBユーザー作成
/*           CREATE LOGIN dms_user WITH PASSWORD = 'Admin_123!!';
             GO
             USE AVG02;
             CREATE USER dms_user FOR LOGIN dms_user;
             ALTER ROLE [db_owner] ADD MEMBER dms_user;
             GO
             USE master;
             CREATE USER dms_user FOR LOGIN dms_user;
             GRANT SELECT ON FN_DBLOG TO dms_user;
             GRANT VIEW SERVER STATE TO dms_user;
             GO
             use msdb;
             CREATE USER dms_user FOR LOGIN dms_user;
             GRANT EXECUTE ON MSDB.DBO.SP_STOP_JOB TO dms_user;
             GRANT EXECUTE ON MSDB.DBO.SP_START_JOB TO dms_user;
             GRANT SELECT ON MSDB.DBO.BACKUPSET TO dms_user;
             GRANT SELECT ON MSDB.DBO.BACKUPMEDIAFAMILY TO dms_user;
             GRANT SELECT ON MSDB.DBO.BACKUPFILE TO dms_user;
             GO  
*/
# 3. DMS設定 CDC（Change Data Capture）
/*           use AVG01
             GO
             EXEC sys.sp_cdc_enable_db  
             GO
             sp_get_distributor
             -- インデックスorプライマリーキーあり
             use AVG01
             GO
             exec sys.sp_cdc_enable_table
             @source_schema = N'schema_name',
             @source_name = N'table_name',
             @index_name = N'unique_index_name'
             @role_name = NULL,
             @supports_net_changes = 1
             GO
             -- インデックスorプライマリーキーなし
             use AVG01
             GO
             exec sys.sp_cdc_enable_table
             @source_schema = N'schxxema01',
             @source_name = N'table01',
             @role_name = NULL
             GO
*/
# 4. パブリッシャーを作成
#      4-1. トランザクションパブリケーションを選択
#      4-2. 対象のテーブルを選択
#      4-3. SQLServerエージェントサービスのアカウントで実行する
#
# 5. ターゲット作成
/*           CREATE LOGIN dms_user WITH PASSWORD = 'Admin_123!!';
             GO
             CREATE DATABASE AVG02;
             GO
             USE AVG02
             GO
             CREATE USER dms_user FOR LOGIN dms_user;
             ALTER ROLE db_owner ADD MEMBER dms_user
             GO
*/
#
#

# 1st instance
resource "aws_instance" "allwaysonag01" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1a"].id
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address,
      user_data
    ]
  }

  # 初期設定
  user_data = <<EOF
  <powershell>
  # オリジナル管理ユーザー作成
  New-LocalUser -Name ${var.tags_owner} -Password (ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force) -PasswordNeverExpires
  Add-LocalGroupMember -Group Administrators -Member ${var.tags_owner}
  
  # S3（s3://aws-aqua-terraform/koizumi/windows）より各種アプリダウンロード
  New-Item "C:\applications" -ItemType "directory"
  Read-S3Object -BucketName aws-aqua-terraform -Prefix koizumi/windows -Folder "C:\applications"
  
  # 日本時間
  Set-TimeZone -Id "Tokyo Standard Time"
  
  # 日本語キーボード設定
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00000000 -Value kbd106.dll
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00010002 -Value kbd106.dll

  # ホスト名変更
  Rename-Computer -NewName allwaysonag01 -Force

  # Telnet インストール
  Install-WindowsFeature "telnet-client"

  # ドメインコントローラーのインストール
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
  Install-WindowsFeature DNS -IncludeManagementTools

  # failover cluster インストール
  Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools

  # Administrator パスワード変更
  $Password = ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force
  $UserAccount = Get-LocalUser -Name Administrator
  $UserAccount | Set-LocalUser -Password $Password

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-allwaysonag01"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# 2nd instance
resource "aws_instance" "allwaysonag02" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1b"].id
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address,
      user_data
    ]
  }

  # 初期設定
  user_data = <<EOF
  <powershell>
  # オリジナル管理ユーザー作成
  New-LocalUser -Name ${var.tags_owner} -Password (ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force) -PasswordNeverExpires
  Add-LocalGroupMember -Group Administrators -Member ${var.tags_owner}
  
  # S3（s3://aws-aqua-terraform/koizumi/windows）より各種アプリダウンロード
  New-Item "C:\applications" -ItemType "directory"
  Read-S3Object -BucketName aws-aqua-terraform -Prefix koizumi/windows -Folder "C:\applications"
  
  # 日本時間
  Set-TimeZone -Id "Tokyo Standard Time"
  
  # 日本語キーボード設定
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00000000 -Value kbd106.dll
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00010002 -Value kbd106.dll

  # ホスト名変更
  Rename-Computer -NewName allwaysonag02 -Force

  # Telnet インストール
  Install-WindowsFeature "telnet-client"

  # ドメインコントローラーのインストール
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
  Install-WindowsFeature DNS -IncludeManagementTools
  
  # failover cluster インストール
  Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools

  # Administrator パスワード変更
  $Password = ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force
  $UserAccount = Get-LocalUser -Name Administrator
  $UserAccount | Set-LocalUser -Password $Password

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-allwaysonag02"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}


/*                    -- DMS test data --
-- CREATE USER
CREATE LOGIN xx_adm WITH PASSWORD = 'xx_adm_pass', CHECK_POLICY = OFF;
GO
USE AVG02
CREATE USER xx_adm FOR LOGIN xx_adm WITH DEFAULT_SCHEMA = xx_adm;
GO
ALTER ROLE db_owner ADD MEMBER xx_adm;
GO

-- CREATE TABLE
CREATE SCHEMA xx_adm AUTHORIZATION xx_adm;
GO
CREATE TABLE xx_adm.tab1_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab1_xx00 (id, name) VALUES ('10', '赤鬼');
INSERT INTO xx_adm.tab1_xx00 (id, name) VALUES ('20', '青鬼');
GO
CREATE TABLE xx_adm.tab2_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab2_xx00 (id, name) VALUES ('10', 'みかん');
GO
INSERT INTO xx_adm.tab2_xx00 (id, name) VALUES ('20', 'もも');
GO
CREATE TABLE xx_adm.tab3_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab3_xx00 (id, name) VALUES ('10', 'にんじん');
GO
INSERT INTO xx_adm.tab3_xx00 (id, name) VALUES ('20', 'だいこん');
GO
CREATE TABLE xx_adm.tab4_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab4_xx00 (id, name) VALUES ('10', 'ガンダム');
GO
INSERT INTO xx_adm.tab4_xx00 (id, name) VALUES ('20', 'ザク');
GO
CREATE TABLE xx_adm.tab5_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab5_xx00 (id, name) VALUES ('10', '東京都');
GO
INSERT INTO xx_adm.tab5_xx00 (id, name) VALUES ('20', '千葉県');
GO
CREATE TABLE xx_adm.tab6_xx00 (id integer, name varchar(10));
GO
INSERT INTO xx_adm.tab6_xx00 (id, name) VALUES ('10', '山崎');
GO
INSERT INTO xx_adm.tab6_xx00 (id, name) VALUES ('20', '白州');
GO

-- CDC
use AVG02
GO
EXEC sys.sp_cdc_enable_db  
GO
sp_get_distributor
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab1_xx00',
@role_name = NULL
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab2_xx00',
@role_name = NULL
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab3_xx00',
@role_name = NULL
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab4_xx00',
@role_name = NULL
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab5_xx00',
@role_name = NULL
GO
exec sys.sp_cdc_enable_table
@source_schema = N'xx_adm',
@source_name = N'tab6_xx00',
@role_name = NULL
GO
*/
