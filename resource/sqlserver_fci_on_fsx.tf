# Microsoft Active Directory
#
# 1. install AD modules
# Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
#
# 2. change the Preferred DNS server and Alternate DNS server
# %SystemRoot%\system32\control.exe ncpa.cpl
#
# 3. in the Member of field, select Domain, enter the fully qualified name of your AWS Directory Service directory.
# %SystemRoot%\system32\control.exe sysdm.cpl
#
# 4. authentication
# user = admin 
# pass = %Password%
#
# 5. restart 
#
# 6. login by domain account
# user = admin@domain.com or domain¥admin
# pass = %Password%
#
# 7. create domain user 'xxxx' to group "AWS Delegated Administrators"
#

resource "aws_directory_service_directory" "main" {
  depends_on = [
    aws_instance.win2016sql2016a,
    aws_instance.win2016sql2016b
  ]
  name     = "${var.tags_env}.${var.tags_owner}.com"
  password = var.db_master_password.ad_admin
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = [aws_subnet.ec2["eu-north-1a"].id,aws_subnet.ec2["eu-north-1b"].id]
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# System Manager
#
# 0. set policy to ec2 iam role
#     AmazonSSMManagedInstanceCore, AmazonSSMDirectoryServiceAccess
#
# 1. run command
#     system manager, select document, and run command
#     Check Console if there is a region at the end of the url
#     ex) "https://eu-north-1.console.aws.amazon.com/systems-manager/documents/dev.koizumi.se-from30.com/description?region=eu-north-1"
#
# 2. add instance
#     set Dns Ip Addresses?
#     choose ec2 instances
#     set s3 bucket & pprefix
#     >> run
#     >> windows 端末は成功しない。調査結果、原因不明 error log --> %windir%\debug\Netsetup.log
#
resource "aws_ssm_document" "ec2join" {
  name  = aws_directory_service_directory.main.name
  document_type = "Command"
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
  lifecycle {
    ignore_changes = [
      content # not allowed update in ver1.2
    ]
  }
  content = <<DOC
{
  "schemaVersion": "1.2",
  "description": "Join your instances to an AWS Directory Service domain.",
  "parameters": {
    "directoryId": {
      "type": "String",
      "default": "${aws_directory_service_directory.main.id}",
      "description": "(Required) The ID of the AWS Directory Service directory."
    },
    "directoryName": {
      "type": "String",
      "default": "${aws_directory_service_directory.main.name}",
      "description": "(Required) The name of the directory; for example, test.example.com"
    },
    "directoryOU": {
      "type": "String",
      "default": "",
      "description": "(Optional) The Organizational Unit (OU) and Directory Components (DC) for the directory; for example, OU=test,DC=example,DC=com"
    },
    "dnsIpAddresses": {
      "type": "StringList",
      "default": [],
      "description": "(Optional) The IP addresses of the DNS servers in the directory. Required when DHCP is not configured. Learn more at https://docs.aws.amazon.com/directoryservice/latest/admin-guide/simple_ad_dns.html",
      "allowedPattern": "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    }
  },
  "runtimeConfig": {
    "aws:domainJoin": {
      "properties": {
        "directoryId": "${aws_directory_service_directory.main.id}",
        "directoryName": "${aws_directory_service_directory.main.name}",
        "directoryOU": "{{ directoryOU }}",
        "dnsIpAddresses": "{{ dnsIpAddresses }}"
      }
    }
  }
}
DOC
}

resource "aws_ssm_association" "ec2_amzn2" {
  name = aws_ssm_document.ec2join.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ec2_amzn2.id]
  }
}

/*
resource "aws_ssm_association" "ec2_win2019" {
  name = aws_ssm_document.ec2join.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ec2_win2019.id]
  }
}

resource "aws_ssm_association" "win2016sql2016a" {
  name = aws_ssm_document.ec2join.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.win2016sql2016a.id]
  }
}

resource "aws_ssm_association" "win2016sql2016b" {
  name = aws_ssm_document.ec2join.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.win2016sql2016b.id]
  }
}
*/


/* 
# SQLServer Failover Cluster
#
#
【ネットワーク要件】
https://docs.microsoft.com/en-US/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements


1. win2016sql2016a,win2016sql2016b の設定変更
    failover cluster インストール
    NICのipv4設定　①プライベートIPを静的指定　②DNSをADのipに指定　③DNSサフィックスにドメイン追加
    FireWall off
    SSMS インストール
    DNS参加　%SystemRoot%\system32\control.exe sysdm.cpl
    再起動

2. Create Users & Add to group "AWS Delegated Administrators"
    domain\sqlsa

3. Allow domain\users to access Common Fsx
    $FSX = "amznfsx4a8gjkg1.dev.koizumi.com" ## Amazon FSx DNS Name
    $FSxPS = "amznfsxu9iqpg2o.dev.koizumi.com" # Amazon FSx PowerShell endpoint

    New-Item -ItemType Directory -Name SQLDB -Path \\$FSX\D$\

    $ACL = Get-Acl \\$FSx\D$\SQLDB
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.com\Admin',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Ar)
    Set-Acl \\$FSX\D$\SQLDB $ACL

    $ACL = Get-Acl \\$FSx\D$\SQLDB
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.com\sqlsa',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Ar)
    Set-Acl \\$FSX\D$\SQLDB $ACL

    $usSession = New-PSSessionOption -Culture en-US -UICulture en-US
    Invoke-Command -ComputerName $FSxPS -SessionOption $usSession -ConfigurationName FSxRemoteAdmin -scriptblock {
        New-FSxSmbShare -Name "SQLDB" -Path "D:\SQLDB" -Description "SQL Database Share" -FolderEnumerationMode AccessBased -EncryptData $True 
        Grant-FSxSmbShareaccess -name SQLDB -AccountName "dev.koizumi.com\sqlsa","dev.koizumi.com\Admin" -accessright Full
    }

    #共有ストレージのマウント用コマンド
    New-PSDrive S -PSProvider FileSystem  -Root \\amznfsx4a8gjkg1.dev.koizumi.com\D$ -Persist
    New-PSDrive U -PSProvider FileSystem  -Root \\fs-097fb4054c4a44b64.dev.koizumi.com\D$ -Persist

4. Failover Clustering の設定

5. ドメインで、Cluster にコンピュータオブジェクト作成の権限を付与

6. SQLServer Cluster インストール
    最後の方で、data ディスクを Fsx に指定する。

7. SQLServer Cluster にノードを追加

8. 共有ストレージに対して、quorum を設定
    $FSX = "fs-097fb4054c4a44b64.dev.koizumi.com" ## Amazon FSx DNS Name
    $FSxPS = "fs-097fb4054c4a44b64.dev.koizumi.com" # Amazon FSx PowerShell endpoint

    New-Item -ItemType Directory -Name QUORUM -Path \\$FSX\D$\

    $ACL = Get-Acl \\$FSx\D$\QUORUM
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.com\Admin',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Ar)
    Set-Acl \\$FSX\D$\QUORUM $ACL

    $ACL = Get-Acl \\$FSx\D$\QUORUM
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.com\salsa',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Ar)
    Set-Acl \\$FSX\D$\QUORUM $ACL

    $usSession = New-PSSessionOption -Culture en-US -UICulture en-US
    Invoke-Command -ComputerName $FSxPS -SessionOption $usSession -ConfigurationName FSxRemoteAdmin -scriptblock {
        New-FSxSmbShare -Name "QUORUM" -Path "D:\QUORUM" -Description "SQL Database Share" -FolderEnumerationMode AccessBased -EncryptData $True 
        Grant-FSxSmbShareaccess -name QUORUM -AccountName "dev.koizumi.com\sqlsa","dev.koizumi.com\Admin" -accessright Full
    }

9. 接続方法
    server name : MSCSSQL2\MSSQLSERVER2
    Authenticate: Windows

10. SQLServer ドメインユーザー追加
    CREATE LOGIN [dev\Admin] FROM WINDOWS;

11. 接続先確認SQL
    SELECT @@SERVERNAME
    SELECT * FROM sys.dm_exec_connections 

12. DNSキャッシュクリア
    Clear-DnsClientCache



【SQLServer 準備作業（source編）】
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

-- MS-CDC設定
use [testdb01]
EXEC sys.sp_cdc_enable_db  
GO
exec sys.sp_cdc_enable_table
@source_schema = N'schema01',
@source_name = N'table01',
@role_name = NULL
GO

*/


data "aws_ami" "win2016sql2016_ami" {
/*  search ami
aws ec2 describe-images \
    --owners self amazon \
    --filters "Name=name,Values=Windows_Server-2016-Japanese-Full-Base-*" \
    --query 'sort_by(Images[].{date:CreationDate,imid:ImageId,name:ImageLocation},&date)'  \
    --output text >> ec2_list.txt
### --filters "Name=name,Values=Windows_Server-2016-English-Full-SQL_2016_SP2_Standard-*" \
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
  private_ip = "10.0.1.83"
  secondary_private_ips = ["10.0.1.84","10.0.1.86"]
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # 下記の項目が変更されると強制的にリソースの再作成が行われてしまうのでそれを防ぐ。
  # ・ami は一定期間で最新版にアップデートされる。
  # ・associate_public_ip_address はインスタンスがシャットダウンすると false に変更される。
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

  # ドメイン参加
  # $User = "${var.tags_env}\Admin"
  # $PWord = ConvertTo-SecureString -String "${var.db_master_password.ad_admin}" -AsPlainText -Force
  # $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
  # Add-Computer -DomainName "${var.tags_env}.${var.tags_owner}.com" -Credential $Credential -Force

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
/*
# Elastic IP
resource "aws_eip" "win2016sql2016a" {
  vpc      = true
  instance = aws_instance.win2016sql2016a.id
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# Private IP
resource "aws_network_interface" "win2016sql2016a" {
  subnet_id       = aws_subnet.ec2["eu-north-1a"].id
  security_groups = [aws_security_group.ec2.id]
  attachment {
    instance     = aws_instance.win2016sql2016a.id
    device_index = 1
  }
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
*/
# 2nd instance
resource "aws_instance" "win2016sql2016b" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1b"].id
  private_ip = "10.0.1.111"
  secondary_private_ips = ["10.0.1.112","10.0.1.113"]
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # 下記の項目が変更されると強制的にリソースの再作成が行われてしまうのでそれを防ぐ。
  # ・ami は一定期間で最新版にアップデートされる。
  # ・associate_public_ip_address はインスタンスがシャットダウンすると false に変更される。
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

  # ドメイン参加
  # $User = "${var.tags_env}\Admin"
  # $PWord = ConvertTo-SecureString -String "${var.db_master_password.ad_admin}" -AsPlainText -Force
  # $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
  # Add-Computer -DomainName "${var.tags_env}.${var.tags_owner}.com" -Credential $Credential -Force
  
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
/*
# Elastic IP
resource "aws_eip" "win2016sql2016b" {
  vpc      = true
  instance = aws_instance.win2016sql2016b.id
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016b"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# Private IP
resource "aws_network_interface" "win2016sql2016b" {
  subnet_id       = aws_subnet.ec2["eu-north-1b"].id
  security_groups = [aws_security_group.ec2.id]
  attachment {
    instance     = aws_instance.win2016sql2016b.id
    device_index = 1
  }
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016b"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
*/

# fsx
resource "aws_fsx_windows_file_system" "allwayson" {
  depends_on = [
    aws_instance.win2016sql2016a,
    aws_instance.win2016sql2016b
  ]
  active_directory_id = aws_directory_service_directory.main.id
  storage_capacity    = 100
  subnet_ids          = [aws_subnet.ec2["eu-north-1a"].id,aws_subnet.ec2["eu-north-1b"].id]
  throughput_capacity = 16
  deployment_type     = "MULTI_AZ_1"
  security_group_ids  = [aws_security_group.ec2.id]
  preferred_subnet_id = aws_subnet.ec2["eu-north-1a"].id
  
  /*self_managed_active_directory {
    dns_ips     = [tolist(aws_directory_service_directory.main.dns_ip_addresses)[0],tolist(aws_directory_service_directory.main.dns_ip_addresses)[1]]
    domain_name = aws_directory_service_directory.main.name
    password    = var.db_master_password.ad_admin
    username    = "koizumi"
  }*/

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-fsx"
    Owner = var.tags_owner
    Env   = var.tags_env
  }

}

resource "aws_fsx_windows_file_system" "quorum" {
  depends_on = [
    aws_instance.win2016sql2016a,
    aws_instance.win2016sql2016b
  ]
  active_directory_id = aws_directory_service_directory.main.id
  storage_capacity    = 100
  subnet_ids          = [aws_subnet.ec2["eu-north-1c"].id]
  throughput_capacity = 16
  deployment_type     = "SINGLE_AZ_1"
  security_group_ids  = [aws_security_group.ec2.id]
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-fsx2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }

}

# 3rd Instance
resource "aws_instance" "win2016sql2016c" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1c"].id
  private_ip = "10.0.1.132"
  secondary_private_ips = ["10.0.1.134","10.0.1.135"]
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # 下記の項目が変更されると強制的にリソースの再作成が行われてしまうのでそれを防ぐ。
  # ・ami は一定期間で最新版にアップデートされる。
  # ・associate_public_ip_address はインスタンスがシャットダウンすると false に変更される。
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
  Rename-Computer -NewName win2016sql2016c -Force

  # Telnet インストール
  Install-WindowsFeature "telnet-client"

  # ドメインコントローラーのインストール
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
  Install-WindowsFeature DNS -IncludeManagementTools

  # ドメイン参加
  # $User = "${var.tags_env}\Admin"
  # $PWord = ConvertTo-SecureString -String "${var.db_master_password.ad_admin}" -AsPlainText -Force
  # $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
  # Add-Computer -DomainName "${var.tags_env}.${var.tags_owner}.com" -Credential $Credential -Force
  
  # failover cluster インストール
  Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016c"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_dms_endpoint" "win2016sql2016a" {
  database_name               = "testdb01"
  endpoint_id                 = "${var.tags_owner}-${var.tags_env}-win2016sql2016a-source"
  endpoint_type               = "source"
  engine_name                 = "sqlserver"
  username                    = "dms_user"
  password                    = "Admin_123!!"
  port                        = 1433
  server_name                 = aws_instance.win2016sql2016a.public_dns
  ssl_mode                    = "none"
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016a-source"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}