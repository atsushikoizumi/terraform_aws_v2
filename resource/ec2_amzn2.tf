# aws_ssm_parameter
# https://www.terraform.io/docs/providers/aws/d/ssm_parameter.html
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2_amzn2" {
  depends_on    = [aws_ecr_repository.repository_1]
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

  # 下記の項目が変更されると強制的にリソースの再作成が行われてしまうのでそれを防ぐ。
  # ・ami は一定期間で最新版にアップデートされる。
  # ・associate_public_ip_address はインスタンスがシャットダウンすると false に変更される。
  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address
    ]
  }

  # 初期設定
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

  ### useradd
  useradd ${var.tags_owner}
  usermod -aG wheel ${var.tags_owner}
  echo "${var.tags_owner} ALL=NOPASSWD: ALL" >> /etc/sudoers

  ### git
  yum install -y git
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
  git clone https://github.com/aqua-labo/docker_logikal_backup  /home/${var.tags_owner}/github/docker_logikal_backup
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
  curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  ### python 3.8
  yum install -y make gcc zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel xz-devel
  curl -OL https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz
  tar -xvzf Python-3.8.6.tgz
  ./Python-3.8.6/configure --prefix=/usr/local/python386 --with-ensurepip
  make
  make install
  ln -s /usr/local/python386/bin/python3 /usr/bin/python3
  ln -s /usr/local/python386/bin/pip3 /usr/bin/pip3
  /usr/local/python386/bin/python3.8 -m pip install --upgrade pip

  ### awe cli
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/root/awscliv2.zip"
  unzip /root/awscliv2.zip
  /root/aws/install
  mkdir /root/.aws
  touch /root/.aws/config
  echo "[default]"         >> /root/.aws/config
  echo "region=eu-north-1" >> /root/.aws/config
  echo "output=json"       >> /root/.aws/config
  echo "role_arn=arn:aws:iam::${var.aws_account_id}:role/${var.tags_owner}-${var.tags_env}-role-ec2" >> /root/.aws/config
  echo "credential_source=Ec2InstanceMetadata" >> /root/.aws/config
  cp -r /root/.aws /home/${var.tags_owner}/
  chown -R ${var.tags_owner}.${var.tags_owner} /home/${var.tags_owner}/.aws

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
  echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/${var.tags_owner}/.bash_profile
  
  ### sqlcmd
  curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
  echo 'export PATH=$PATH:/opt/mssql-tools/bin' >> /home/${var.tags_owner}/.bash_profile
  # yum install -y mssql-tools unixODBC-devel   # require "YES" for MS licence
  
  # push ecr
  docker build -t logical_backup:latest ./home/${var.tags_owner}/github/docker_logical_backup
  aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.eu-north-1.amazonaws.com
  docker tag logical_backup:latest ${var.aws_account_id}.dkr.ecr.eu-north-1.amazonaws.com/${var.tags_owner}-${var.tags_env}-repository-1:latest
  docker push ${var.aws_account_id}.dkr.ecr.eu-north-1.amazonaws.com/${var.tags_owner}-${var.tags_env}-repository-1:latest

  # reboot
  reboot

  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-amzn2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}