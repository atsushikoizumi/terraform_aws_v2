/* 
# SQLServer Installer
# https://my.visualstudio.com/benefits
#
【FCI構築手順】

1.  サーバー設定変更（win2016sql2016a/win2016sql2016b）
    AWSコンソール上でセカンダリIPを2つ追加
    ActiveDirectory管理ツールをインストール
    FailoverClusterをインストール
    SSMSをインストール
    NIC > TIC/IPv4 > プロパティ
      ・プライベートIPを静的指定
      ・DNSにADのIPを静的指定
      ・DNSサフィックスに参加ドメイン名追加
    ファイアーウォールを無効化
    コントロールパネル > システム > 設定の変更 > ドメイン参加
    再起動

2. ドメインユーザー作成
    ・ユーザー作成　"domain\sqlsa"
    ・管理者権限付与　"AWS Delegated Administrators"

3. ドメインユーザーにFsx上の共有フォルダへのアクセス権限付与
    ##### PowerShell start #####
    $FSX    = "amznfsx4a8gjkg1.dev.koizumi.com"  # Amazon FSx DNS Name
    $FSxPS  = "amznfsxu9iqpg2o.dev.koizumi.com"  # Amazon FSx PowerShell endpoint
    $Path   = "SQLDB"
    $domain = "dev.koizumi.com"
    $user   = "sqlsa"
    $Drive  = "F"  # サーバーへのマウント用ドライブ

    New-Item -ItemType Directory -Name $Path -Path \\$FSX\D$\

    $ACL = Get-Acl \\$FSx\D$\$Path
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule("$domain\$user","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Ar)
    Set-Acl \\$FSX\D$\$Path $ACL

    $usSession = New-PSSessionOption -Culture en-US -UICulture en-US
    Invoke-Command -ComputerName $FSxPS -SessionOption $usSession -ConfigurationName FSxRemoteAdmin -scriptblock {
        New-FSxSmbShare -Name "$Path" -Path "D:\$Path" -Description "SQL Database Share" -FolderEnumerationMode AccessBased -EncryptData $True 
        Grant-FSxSmbShareaccess -name $Path -AccountName ""$domain\$user"" -accessright Full
    }

    New-PSDrive $Drive -PSProvider FileSystem  -Root \\$FSX\D$ -Persist
    ##### PowerShell end #####

    ※Quorumに対してはshareフォルダで事足りるので設定は不要

4. FailoverCluster の設定

5. ドメインのClusterオブジェクトに対してコンピュータオブジェクト作成の権限を付与

6. SQLServerClusterインストール
    ・混在モード（Server認証 & WIndows認証）を指定
    ・dataディスクにFsx（\\amznfsx4a8gjkg1.dev.koizumi.com\DQLDB）を指定

7. SQLServerClusterノード追加

8. 接続方法
    server name : MSCSSQL2\MSSQLSERVER2
    Authenticate: Windows

9. 接続先確認SQL
    SELECT @@SERVERNAME
    SELECT * FROM sys.dm_exec_connections 
    PS> Clear-DnsClientCache



【DMS 準備作業（publicher編）】
-- ユーザー作成
CREATE LOGIN dms_user WITH PASSWORD = 'Admin_123!!';
ALTER SERVER ROLE [sysadmin] ADD MEMBER dms_user;
GO

-- テスト用データベース作成
CREATE DATABASE testdb01;
GO

-- テストデータ挿入
USE testdb01
GO
CREATE SCHEMA schema01;
GO
CREATE TABLE schema01.table01 (id integer, name varchar(10));
INSERT INTO schema01.table01 (id, name) VALUES ('10', '東京都');
INSERT INTO schema01.table01 (id, name) VALUES ('20', '千葉県');
SELECT * FROM schema01.table01;
GO

-- バックアップ設定
USE master;  
ALTER DATABASE testdb01 SET RECOVERY FULL;  
BACKUP DATABASE testdb01 TO DISK = '\\amznfsx4a8gjkg1.dev.koizumi.com\SQLDB\testdb01FullRM.bak' WITH INIT;
BACKUP LOG testdb01 TO DISK = '\\amznfsx4a8gjkg1.dev.koizumi.com\SQLDB\testdb01FullRM.bak';  
GO 

-- MS-CDC 設定
use [testdb01]
EXEC sys.sp_cdc_enable_db  
GO
exec sys.sp_cdc_enable_table
@source_schema = N'schema01',
@source_name = N'table01',
@role_name = NULL
GO

-- ディストリビューションの構成
SSMS > Replication >


【DMS 準備作業（distributor編）】


*/

# Search ami
data "aws_ami" "win2016sql2016_ami" {
/*  search ami
aws ec2 describe-images \
    --owners self amazon \
    --filters "Name=name,Values=Windows_Server-2016-Japanese-Full-Base-*" \
    --query 'sort_by(Images[].{date:CreationDate,imid:ImageId,name:ImageLocation},&date)'  \
    --output text >> ec2_list.txt
*/
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2016-Japanese-Full-Base-*"]
  }
}

# 1st instance
resource "aws_instance" "win2016sql2016a" {
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
  Rename-Computer -NewName win2016sql2016a -Force

  # Telnet インストール
  Install-WindowsFeature "telnet-client"

  # ドメインコントローラーのインストール
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
  Install-WindowsFeature DNS -IncludeManagementTools

  # failover cluster インストール
  Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# 2nd instance
resource "aws_instance" "win2016sql2016b" {
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
  Rename-Computer -NewName win2016sql2016b -Force

  # Telnet インストール
  Install-WindowsFeature "telnet-client"

  # ドメインコントローラーのインストール
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
  Install-WindowsFeature DNS -IncludeManagementTools
  
  # failover cluster インストール
  Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016b"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

