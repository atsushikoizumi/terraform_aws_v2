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
/*
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