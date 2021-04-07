#
# Database Migration Service requires the below IAM Roles to be created before
# https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole
#
/*
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "${var.tags_owner}-${var.tags_env}-dms-access-for-endpoint"
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms-access-for-endpoint.name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "${var.tags_owner}-${var.tags_env}-dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "${var.tags_owner}-${var.tags_env}-dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}
*/

# Create a new replication subnet group
resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "${var.tags_owner} ${var.tags_env} replication subnet group"
  replication_subnet_group_id          = "${var.tags_owner}-${var.tags_env}-dms-subnet-gp"
  subnet_ids = [
    aws_subnet.ec2["eu-north-1a"].id,aws_subnet.ec2["eu-north-1b"].id,aws_subnet.ec2["eu-north-1c"].id,
    aws_subnet.rds["eu-north-1a"].id,aws_subnet.rds["eu-north-1b"].id,aws_subnet.rds["eu-north-1c"].id
  ]
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# Create a new replication instance
resource "aws_dms_replication_instance" "win2019sql2019a" {
  allocated_storage            = 20
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = "eu-north-1c"
  engine_version               = "3.4.3"
  multi_az                     = false
  preferred_maintenance_window = "sun:16:30-sun:20:30"
  publicly_accessible          = true
  replication_instance_class   = "dms.t3.micro"
  replication_instance_id      = "${var.tags_owner}-${var.tags_env}-win2019sql2019a"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms.id
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

#
# SQLServer on WindowsServer 
#
data "aws_ami" "win2019sql2019_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-Japanese-Full-SQL_2019_Standard-*"]
  }
}

resource "aws_instance" "win2019sql2019a" {
  ami           = data.aws_ami.win2019sql2019_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1c"].id
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
  Rename-Computer -NewName win2019sql2019a -Force

  # Administrator パスワード変更
  $Password = ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force
  $UserAccount = Get-LocalUser -Name Administrator
  $UserAccount | Set-LocalUser -Password $Password

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019a"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_instance" "win2019sql2019b" {
  ami           = data.aws_ami.win2019sql2019_ami.id
  instance_type = "m5.xlarge"
  key_name      = var.ssh_key
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1c"].id
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
  Rename-Computer -NewName win2019sql2019b -Force

  # Administrator パスワード変更
  $Password = ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force
  $UserAccount = Get-LocalUser -Name Administrator
  $UserAccount | Set-LocalUser -Password $Password

  # 再起動
  Restart-Computer
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019b"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

#
# DMS (Database Migration Service)
#

/*  【SQLServer 準備作業（source編）】
# バックアップ用フォルダ作成
# PowerShell
New-Item -ItemType Directory -Name SQLServerBackups -Path C:\
$User_or_Group_Name = "NT SERVICE\MSSQLSERVER"
$Folder_Path = "C:\SQLServerBackups\"
$acl = Get-acl $Folder_Path
$Permission = ("${User_or_Group_Name}","FullControl","ContainerInherit","None","Allow")
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Permission
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $Folder_Path

/* SSMS
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
BACKUP DATABASE testdb01 TO DISK = 'C:\SQLServerBackups\testdb01FullRM.bak' WITH INIT;
BACKUP LOG testdb01 TO DISK = 'C:\SQLServerBackups\testdb01FullRM.bak';  
GO 

-- Login by dms_user
-- ① サーバーのプロパティで Windows認証とサーバー認証にチェックをする。
-- ② SQLServer の保持しているホスト名を変更する。
select @@servername
GO
sp_dropserver 'EC2AMAZ-44246HC';
GO
sp_addserver 'win2019sql2019a', local;
GO
-- ③ サービス > SQLServerサービスのプロパティ > 「デスクトップとの対話をサービスに許可（W）」にチェック
-- ④ SQLServer を再起動する。

-- ディストリビューションを設定 > SSMS > レプリケーション右クリックから
sp_get_distributor

-- MS-CDC の設定 keyあり
-- https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?redirectedfrom=MSDN&view=sql-server-ver15
use [testdb01]
exec sys.sp_cdc_enable_table
@source_schema = N'schema_name',
@source_name = N'table_name',
@index_name = N'unique_index_name'
@role_name = NULL,
@supports_net_changes = 1
GO

-- MS-CDC の設定 keyなし
use [testdb01]
exec sys.sp_cdc_enable_table
@source_schema = N'schema01',
@source_name = N'table01',
@role_name = NULL
GO

  【SQLServer 準備作業（target編）】
-- ① サーバーのプロパティで Windows認証とサーバー認証にチェックをする。
-- ② SQLServer を再起動する。

-- ユーザー作成
CREATE LOGIN dms_user WITH PASSWORD = 'Admin_123!!';
GO

-- テスト用データベース作成
CREATE DATABASE testdb01;
GO

-- dbowner をセットする。
USE testdb01
GO
CREATE USER dms_user FOR LOGIN dms_user;
ALTER ROLE db_owner ADD MEMBER dms_user
GO

*/


#
# Must be after dbuser in sqlserver.
# https://www.youtube.com/watch?v=5VbKYnBn-jU
# Create a new endpoint
resource "aws_dms_endpoint" "win2019sql2019a" {
  database_name               = "testdb01"
  endpoint_id                 = "${var.tags_owner}-${var.tags_env}-win2019sql2019a-source"
  endpoint_type               = "source"
  engine_name                 = "sqlserver"
  username                    = "dms_user"
  password                    = "Admin_123!!"
  port                        = 1433
  server_name                 = aws_instance.win2019sql2019a.public_dns
  ssl_mode                    = "none"
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019a-source"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_dms_endpoint" "win2019sql2019b" {
  database_name               = "testdb01"
  endpoint_id                 = "${var.tags_owner}-${var.tags_env}-win2019sql2019b-target"
  endpoint_type               = "target"
  engine_name                 = "sqlserver"
  username                    = "dms_user"
  password                    = "Admin_123!!"
  port                        = 1433
  server_name                 = aws_instance.win2019sql2019b.public_dns
  ssl_mode                    = "none"
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019b-target"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

#
# aws_dms_replication_task
#
resource "aws_dms_replication_task" "win2019sql2019a" {
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.win2019sql2019a.replication_instance_arn
  replication_task_id       = "${var.tags_owner}-${var.tags_env}-win2019sql2019a-schema01-table01"
  replication_task_settings = "{\"TargetMetadata\":{\"TargetSchema\":\"\",\"SupportLobs\":false,\"FullLobMode\":false,\"LobChunkSize\":0,\"LimitedSizeLobMode\":false,\"LobMaxSize\":0,\"InlineLobMaxSize\":0,\"LoadMaxFileSize\":0,\"ParallelLoadThreads\":0,\"ParallelLoadBufferSize\":0,\"BatchApplyEnabled\":false,\"TaskRecoveryTableEnabled\":false,\"ParallelLoadQueuesPerThread\":0,\"ParallelApplyThreads\":0,\"ParallelApplyBufferSize\":0,\"ParallelApplyQueuesPerThread\":0},\"FullLoadSettings\":{\"TargetTablePrepMode\":\"DROP_AND_CREATE\",\"CreatePkAfterFullLoad\":false,\"StopTaskCachedChangesApplied\":false,\"StopTaskCachedChangesNotApplied\":false,\"MaxFullLoadSubTasks\":8,\"TransactionConsistencyTimeout\":600,\"CommitRate\":10000},\"Logging\":{\"EnableLogging\":false,\"LogComponents\":[{\"Id\":\"TRANSFORMATION\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SOURCE_UNLOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"IO\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_LOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"PERFORMANCE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SOURCE_CAPTURE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SORTER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"REST_SERVER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"VALIDATOR_EXT\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_APPLY\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TASK_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TABLES_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"METADATA_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"FILE_FACTORY\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"COMMON\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"ADDONS\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"DATA_STRUCTURE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"COMMUNICATION\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"FILE_TRANSFER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"}],\"CloudWatchLogGroup\":null,\"CloudWatchLogStream\":null},\"ControlTablesSettings\":{\"historyTimeslotInMinutes\":5,\"ControlSchema\":\"\",\"HistoryTimeslotInMinutes\":5,\"HistoryTableEnabled\":false,\"SuspendedTablesTableEnabled\":false,\"StatusTableEnabled\":false,\"FullLoadExceptionTableEnabled\":false},\"StreamBufferSettings\":{\"StreamBufferCount\":3,\"StreamBufferSizeInMB\":8,\"CtrlStreamBufferSizeInMB\":5},\"ChangeProcessingDdlHandlingPolicy\":{\"HandleSourceTableDropped\":true,\"HandleSourceTableTruncated\":true,\"HandleSourceTableAltered\":true},\"ErrorBehavior\":{\"DataErrorPolicy\":\"LOG_ERROR\",\"DataTruncationErrorPolicy\":\"LOG_ERROR\",\"DataErrorEscalationPolicy\":\"SUSPEND_TABLE\",\"DataErrorEscalationCount\":0,\"TableErrorPolicy\":\"SUSPEND_TABLE\",\"TableErrorEscalationPolicy\":\"STOP_TASK\",\"TableErrorEscalationCount\":0,\"RecoverableErrorCount\":-1,\"RecoverableErrorInterval\":5,\"RecoverableErrorThrottling\":true,\"RecoverableErrorThrottlingMax\":1800,\"RecoverableErrorStopRetryAfterThrottlingMax\":true,\"ApplyErrorDeletePolicy\":\"IGNORE_RECORD\",\"ApplyErrorInsertPolicy\":\"LOG_ERROR\",\"ApplyErrorUpdatePolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationPolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationCount\":0,\"ApplyErrorFailOnTruncationDdl\":false,\"FullLoadIgnoreConflicts\":true,\"FailOnTransactionConsistencyBreached\":false,\"FailOnNoTablesCaptured\":true},\"ChangeProcessingTuning\":{\"BatchApplyPreserveTransaction\":true,\"BatchApplyTimeoutMin\":1,\"BatchApplyTimeoutMax\":30,\"BatchApplyMemoryLimit\":500,\"BatchSplitSize\":0,\"MinTransactionSize\":1000,\"CommitTimeout\":1,\"MemoryLimitTotal\":1024,\"MemoryKeepTime\":60,\"StatementCacheSize\":50},\"PostProcessingRules\":null,\"CharacterSetSettings\":null,\"LoopbackPreventionSettings\":null,\"BeforeImageSettings\":null,\"FailTaskWhenCleanTaskResourceFailed\":false}"
  source_endpoint_arn       = aws_dms_endpoint.win2019sql2019a.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.win2019sql2019b.endpoint_arn
  table_mappings            = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"schema01\",\"table-name\":\"table01\"},\"rule-action\":\"include\",\"filters\":[]}]}"
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019sql2019a-schema01-table01"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_dms_replication_task" "win2016sql2016a" {
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.win2019sql2019a.replication_instance_arn
  replication_task_id       = "${var.tags_owner}-${var.tags_env}-win2016sql2016a-schema01-table01"
  replication_task_settings = "{\"TargetMetadata\":{\"TargetSchema\":\"\",\"SupportLobs\":false,\"FullLobMode\":false,\"LobChunkSize\":0,\"LimitedSizeLobMode\":false,\"LobMaxSize\":0,\"InlineLobMaxSize\":0,\"LoadMaxFileSize\":0,\"ParallelLoadThreads\":0,\"ParallelLoadBufferSize\":0,\"BatchApplyEnabled\":false,\"TaskRecoveryTableEnabled\":false,\"ParallelLoadQueuesPerThread\":0,\"ParallelApplyThreads\":0,\"ParallelApplyBufferSize\":0,\"ParallelApplyQueuesPerThread\":0},\"FullLoadSettings\":{\"TargetTablePrepMode\":\"DROP_AND_CREATE\",\"CreatePkAfterFullLoad\":false,\"StopTaskCachedChangesApplied\":false,\"StopTaskCachedChangesNotApplied\":false,\"MaxFullLoadSubTasks\":8,\"TransactionConsistencyTimeout\":600,\"CommitRate\":10000},\"Logging\":{\"EnableLogging\":false,\"LogComponents\":[{\"Id\":\"TRANSFORMATION\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SOURCE_UNLOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"IO\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_LOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"PERFORMANCE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SOURCE_CAPTURE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SORTER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"REST_SERVER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"VALIDATOR_EXT\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_APPLY\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TASK_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TABLES_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"METADATA_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"FILE_FACTORY\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"COMMON\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"ADDONS\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"DATA_STRUCTURE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"COMMUNICATION\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"FILE_TRANSFER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"}],\"CloudWatchLogGroup\":null,\"CloudWatchLogStream\":null},\"ControlTablesSettings\":{\"historyTimeslotInMinutes\":5,\"ControlSchema\":\"\",\"HistoryTimeslotInMinutes\":5,\"HistoryTableEnabled\":false,\"SuspendedTablesTableEnabled\":false,\"StatusTableEnabled\":false,\"FullLoadExceptionTableEnabled\":false},\"StreamBufferSettings\":{\"StreamBufferCount\":3,\"StreamBufferSizeInMB\":8,\"CtrlStreamBufferSizeInMB\":5},\"ChangeProcessingDdlHandlingPolicy\":{\"HandleSourceTableDropped\":true,\"HandleSourceTableTruncated\":true,\"HandleSourceTableAltered\":true},\"ErrorBehavior\":{\"DataErrorPolicy\":\"LOG_ERROR\",\"DataTruncationErrorPolicy\":\"LOG_ERROR\",\"DataErrorEscalationPolicy\":\"SUSPEND_TABLE\",\"DataErrorEscalationCount\":0,\"TableErrorPolicy\":\"SUSPEND_TABLE\",\"TableErrorEscalationPolicy\":\"STOP_TASK\",\"TableErrorEscalationCount\":0,\"RecoverableErrorCount\":-1,\"RecoverableErrorInterval\":5,\"RecoverableErrorThrottling\":true,\"RecoverableErrorThrottlingMax\":1800,\"RecoverableErrorStopRetryAfterThrottlingMax\":true,\"ApplyErrorDeletePolicy\":\"IGNORE_RECORD\",\"ApplyErrorInsertPolicy\":\"LOG_ERROR\",\"ApplyErrorUpdatePolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationPolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationCount\":0,\"ApplyErrorFailOnTruncationDdl\":false,\"FullLoadIgnoreConflicts\":true,\"FailOnTransactionConsistencyBreached\":false,\"FailOnNoTablesCaptured\":true},\"ChangeProcessingTuning\":{\"BatchApplyPreserveTransaction\":true,\"BatchApplyTimeoutMin\":1,\"BatchApplyTimeoutMax\":30,\"BatchApplyMemoryLimit\":500,\"BatchSplitSize\":0,\"MinTransactionSize\":1000,\"CommitTimeout\":1,\"MemoryLimitTotal\":1024,\"MemoryKeepTime\":60,\"StatementCacheSize\":50},\"PostProcessingRules\":null,\"CharacterSetSettings\":null,\"LoopbackPreventionSettings\":null,\"BeforeImageSettings\":null,\"FailTaskWhenCleanTaskResourceFailed\":false}"
  source_endpoint_arn       = aws_dms_endpoint.win2016sql2016a.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.win2019sql2019b.endpoint_arn
  table_mappings            = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"schema01\",\"table-name\":\"table02\"},\"rule-action\":\"include\",\"filters\":[]}]}"
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2016sql2016a-schema01-table01"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}
