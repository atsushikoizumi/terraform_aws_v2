/* 
## 1. search ami
aws ec2 describe-images \
    --owners self amazon \
    --filters "Name=name,Values=Windows_Server-2016-English-Full-SQL_2016_SP2_Standard-*" \
    --query 'sort_by(Images[].{date:CreationDate,imid:ImageId,name:ImageLocation},&date)'  \
    --output text >> ec2_list.txt

## 2. mount
New-PSDrive D -PSProvider FileSystem  -Root \\amznfsxmyafmcad.dev.koizumi.se-from30.com\D$ -Persist

## 3. Create Users & Add to group "AWS Delegated Administrators"
domain\DBAdmins
domain\SQLSA
domain\SQLServers

## 4-1. Allow domain\users to access Fsx
$FSX = "amznfsxmyafmcad.dev.koizumi.se-from30.com" ## Amazon FSx DNS Name
$FSxPS = "amznfsxen2edrpe.dev.koizumi.se-from30.com" # Amazon FSx PowerShell endpoint

New-Item -ItemType Directory -Name SQLDB -Path \\$FSX\D$\

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\DBAdmins',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\SQLSA',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\SQLServers',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$usSession = New-PSSessionOption -Culture en-US -UICulture en-US
Invoke-Command -ComputerName $FSxPS -SessionOption $usSession -ConfigurationName FSxRemoteAdmin -scriptblock {
    New-FSxSmbShare -Name "SQLDB" -Path "D:\SQLDB" -Description "SQL Database Share" -FolderEnumerationMode AccessBased -EncryptData $True 
    Grant-FSxSmbShareaccess -name SQLDB -AccountName "dev.koizumi.se-from30.com\SQLSA","dev.koizumi.se-from30.com\DBAdmins","dev.koizumi.se-from30.com\SQLServers" -accessright Full
}

## 4-2. the same as quorum Fsx
$FSX = "fs-06a57ee08c411d72d.dev.koizumi.se-from30.com" ## Amazon FSx DNS Name
$FSxPS = "fs-06a57ee08c411d72d.dev.koizumi.se-from30.com" # Amazon FSx PowerShell endpoint

New-Item -ItemType Directory -Name SQLDB -Path \\$FSX\D$\

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\DBAdmins',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\SQLSA',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$ACL = Get-Acl \\$FSx\D$\SQLDB
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule('dev.koizumi.se-from30.com\SQLServers',"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($Ar)
Set-Acl \\$FSX\D$\SQLDB $ACL

$usSession = New-PSSessionOption -Culture en-US -UICulture en-US
Invoke-Command -ComputerName $FSxPS -SessionOption $usSession -ConfigurationName FSxRemoteAdmin -scriptblock {
    New-FSxSmbShare -Name "SQLDB" -Path "D:\SQLDB" -Description "SQL Database Share" -FolderEnumerationMode AccessBased -EncryptData $True 
    Grant-FSxSmbShareaccess -name SQLDB -AccountName "dev.koizumi.se-from30.com\SQLSA","dev.koizumi.se-from30.com\DBAdmins","dev.koizumi.se-from30.com\SQLServers" -accessright Full
}

## 5. Install Fail over cluster

## 6. Change Main NIC Static

## 7. 

*/
#
#
data "aws_ami" "win2016sql2016_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-SQL_2016_SP2_*"]
  }
}

# 1st instance
resource "aws_instance" "win2016sql2016a" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "t3.xlarge"
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
# add 2nic to instance 1st
resource "aws_network_interface" "win2016sql2016a1" {
  subnet_id       = aws_subnet.ec2["eu-north-1a"].id
  security_groups = [aws_security_group.ec2.id]

  attachment {
    instance     = aws_instance.win2016sql2016a.id
    device_index = 1
  }
}

resource "aws_network_interface" "win2016sql2016a2" {
  subnet_id       = aws_subnet.ec2["eu-north-1a"].id
  security_groups = [aws_security_group.ec2.id]

  attachment {
    instance     = aws_instance.win2016sql2016a.id
    device_index = 2
  }
}*/

# 2nd instance
resource "aws_instance" "win2016sql2016b" {
  ami           = data.aws_ami.win2016sql2016_ami.id
  instance_type = "t3.xlarge"
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
# add nic to instance 2nd
resource "aws_network_interface" "win2016sql2016b1" {
  subnet_id       = aws_subnet.ec2["eu-north-1b"].id
  security_groups = [aws_security_group.ec2.id]

  attachment {
    instance     = aws_instance.win2016sql2016b.id
    device_index = 1
  }
}

resource "aws_network_interface" "win2016sql2016b2" {
  subnet_id       = aws_subnet.ec2["eu-north-1b"].id
  security_groups = [aws_security_group.ec2.id]

  attachment {
    instance     = aws_instance.win2016sql2016b.id
    device_index = 2
  }
}*/

# fsx
resource "aws_fsx_windows_file_system" "allwayson" {
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
