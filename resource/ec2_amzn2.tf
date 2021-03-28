# aws_ssm_parameter
# https://www.terraform.io/docs/providers/aws/d/ssm_parameter.html
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2_amzn2" {

  # 基本設定
  ami           = data.aws_ssm_parameter.amzn2_ami.value
  instance_type = "t3.micro" # eu-north-1 ではこれが最小サイズ
  key_name      = aws_key_pair.key_pair.key_name
  # key_name      = "your-key-name"
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

  # user_data 内の処理における他リソースとの依存関係は terraform では自動解決できない。
  depends_on = [aws_efs_mount_target.logicalbackup]

  # 初回起動時に以下のコマンドを root で自動実行
  user_data = <<EOF
  #!/bin/bash
  yum update -y
  yum install -y curl unzip jq

  ### JST
  sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock
  sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock
  ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

  ### locale
  sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n

  ### useradd
  useradd ${var.tags_owner}
  usermod -aG wheel ${var.tags_owner}
  echo "${var.tags_owner} ALL=NOPASSWD: ALL" >> /etc/sudoers
  mkdir /home/${var.tags_owner}/.ssh/
  cp /home/ec2-user/.ssh/authorized_keys /home/${var.tags_owner}/.ssh/
  chown -R ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/.ssh/

  ### git
  amazon-linux-extras install epel
  yum install -y git git-lfs
  touch /root/.gitconfig
  echo "[user]" >> /root/.gitconfig
  echo "name = ${var.tags_owner}-${var.tags_env}" >> /root/.gitconfig
  echo "email = ${var.git_account}" >> /root/.gitconfig
  touch /root/.netrc
  echo "machine github.com" >> /root/.netrc
  echo "login ${var.git_account}" >> /root/.netrc
  echo "password ${var.git_pass}" >> /root/.netrc
  chmod 600 /root/.netrc
  mkdir /home/${var.tags_owner}/github/
  git clone https://github.com/aqua-labo/mysql_logical_backup_shellscript  /home/${var.tags_owner}/github/mysql_logical_backup_shellscript
  git clone https://github.com/aqua-labo/oracle_audit_shellscript  /home/${var.tags_owner}/github/oracle_audit_shellscript
  git clone https://github.com/aqua-labo/postgresql_audit_shellscript  /home/${var.tags_owner}/github/postgresql_audit_shellscript
  git clone https://github.com/aqua-labo/postgresql_logical_backup_shellscript  /home/${var.tags_owner}/github/postgresql_logical_backup_shellscript
  git clone https://github.com/aqua-labo/isid_env_dev  /home/${var.tags_owner}/github/isid_env_dev
  git clone https://github.com/atsushikoizumi/aws_db_logical_backup  /home/${var.tags_owner}/github/aws_db_logical_backup
  git clone https://github.com/atsushikoizumi/sql_syntax /home/${var.tags_owner}/github/sql_syntax
  mv /root/.gitconfig /home/${var.tags_owner}/
  mv /root/.netrc /home/${var.tags_owner}/
  chown -R ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/github
  chown ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/.gitconfig
  chown ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/.netrc

  ### docker
  amazon-linux-extras install docker
  yum install -y docker
  usermod -a -G docker ${var.tags_owner}
  systemctl enable docker
  systemctl start docker
  curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  ### python 3.8.6
  yum install -y make gcc zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel xz-devel unixODBC unixODBC-devel libaio gcc-c++
  mkdir /tmp/src/
  curl -L https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz -o /tmp/src/Python-3.8.6.tgz
  cd /tmp/src/; tar -xvzf Python-3.8.6.tgz
  cd /tmp/src/; ./Python-3.8.6/configure --prefix=/usr/local/python386 --with-ensurepip
  cd /tmp/src/; make
  cd /tmp/src/; make install
  ln -s /usr/local/python386/bin/python3 /usr/bin/python3
  ln -s /usr/local/python386/bin/pip3 /usr/bin/pip3
  python3 -m pip install --upgrade pip
  python3 -m pip install wheel boto3 datetime pandas numpy
  python3 -m pip install pyodbc

  ### awe cli
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/root/awscliv2.zip"
  unzip /root/awscliv2.zip
  /aws/install
  mkdir /root/.aws
  touch /root/.aws/config
  echo "[default]"         >> /root/.aws/config
  echo "region=eu-north-1" >> /root/.aws/config
  echo "output=json"       >> /root/.aws/config
  cp -r /root/.aws /home/${var.tags_owner}/
  chown -R ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/.aws

  ### amazon-efs-utils
  yum install -y amazon-efs-utils
  mkdir /home/koizumi/efs
  chown ${var.tags_owner}.${var.tags_owner} /home/koizumi/efs
  mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-26d86ab7.efs.eu-north-1.amazonaws.com:/ /home/koizumi/efs

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

  ### sqlplus & odbc
  mkdir /opt/oracle
  curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm -o /opt/oracle/oracle-instantclient-basic-linuxx64.rpm
  curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm -o /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm
  curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-odbc-linuxx64.rpm -o /opt/oracle/oracle-instantclient-odbc-linuxx64.rpm
  yum install -y /opt/oracle/oracle-instantclient-basic-linuxx64.rpm
  yum install -y /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm
  yum install -y /opt/oracle/oracle-instantclient-odbc-linuxx64.rpm
  touch /etc/odbc.ini
  /usr/lib/oracle/19.9/client64/bin/odbc_update_ini.sh "/"  "/usr/lib/oracle/19.9/client64/lib" "ORACLEODBCDRIVER" RDSORCL /etc/odbc.ini
  odbcinst -i -d -f /etc/odbcinst.ini
  echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/${var.tags_owner}/.bash_profile
  
  ### sqlcmd
  curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
  echo 'export PATH=$PATH:/opt/mssql-tools/bin' >> /home/${var.tags_owner}/.bash_profile
  ACCEPT_EULA=Y yum install -y mssql-tools

  # userdel
  userdel ec2-user

  # 実行結果の確認  cat /var/log/cloud-init-output.log

  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-amzn2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}