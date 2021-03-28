# Microsoft Active Directory
#
# 1. set policy to ec2 iam role
# AmazonSSMManagedInstanceCore
# AmazonSSMDirectoryServiceAccess
#
# 2. install AD modules
# Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
#
# 3. change the Preferred DNS server and Alternate DNS server
# %SystemRoot%\system32\control.exe ncpa.cpl
#
# 4. in the Member of field, select Domain, enter the fully qualified name of your AWS Directory Service directory.
# %SystemRoot%\system32\control.exe sysdm.cpl
#
# 5. authentication
# user = admin 
# pass = %Password%
#
# 6. restart 
#
# 7. login by domain account
# user = admin@domain.com or domain¥admin
# pass = %Password%
#
# 8. create user & group, and mapping users
#
# 9. grant privilege to group in the server or database.
#

resource "aws_directory_service_directory" "main" {
  name     = "${var.tags_env}.${var.tags_owner}.se-from30.com"
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
