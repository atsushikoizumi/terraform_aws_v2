# aws_ssm_parameter
# https://www.terraform.io/docs/providers/aws/d/ssm_parameter.html
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2_amzn2" {
  ami           = data.aws_ssm_parameter.amzn2_ami.value
  instance_type = "t3.micro" # eu-north-1 ではこれが最小サイズ
  key_name      = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1a"].id
  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data                   = <<EOF
  #!/bin/bash
  yum update -y
  yum install -y curl
  yum install -y unzip

  ### JST
  sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock
  sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock
  ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

  ### locale
  sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n

  ### git
  yum install -y git
 
  ### docker
  amazon-linux-extras install docker
  yum install -y docker
  usermod -a -G docker ec2-user
  systemctl enable docker
  curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  ### awe cli
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/root/awscliv2.zip"
  unzip /root/awscliv2.zip
  /root/aws/install
  mkdir /root/.aws
  touch /root/.aws/config
  echo "[default]"         >> /root/.aws/config
  echo "region=eu-north-1" >> /root/.aws/config
  echo "output=json"       >> /root/.aws/config
  cp -r /root/.aws /home/ec2-user/
  chown -R ec2-user.ec2-user /home/ec2-user/.aws

  ### mysql
  yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
  yum install -y yum-utils
  yum-config-manager --disable mysql80-community
  yum-config-manager --enable mysql57-community
  yum install -y mysql-community-client
  
  ### psql
  rpm -ivh --nodeps https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  sed -i "s/\$releasever/7/g" "/etc/yum.repos.d/pgdg-redhat-all.repo"
  yum install -y postgresql12

  ### sqlplus
  curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm -o oracle-instantclient-basic-linuxx64.rpm
  curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm -o oracle-instantclient-sqlplus-linuxx64.rpm
  yum install -y oracle-instantclient-basic-linuxx64.rpm
  yum install -y oracle-instantclient-sqlplus-linuxx64.rpm
  echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/ec2-user/.bash_profile
  
  ### sqlcmd
  curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
  echo 'export PATH=$PATH:/opt/mssql-tools/bin' >> /home/ec2-user/.bash_profile
  # yum install -y mssql-tools unixODBC-devel   # require "YES" for MS licence
  
  # reboot
  reboot

  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-amzn2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}