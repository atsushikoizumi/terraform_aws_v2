# ベースイメージ
FROM amazonlinux:2

# AWSリージョン設定
ENV AWS_region ap-northeast-1
e
# 初期設定
RUN yum -y update && \
    # 追加で必要なパッケージをインストール
    rpm -ivh --nodeps https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    sed -i "s/\$releasever/7/g" "/etc/yum.repos.d/pgdg-redhat-all.repo" && \
    yum -y install awscli jq postgresql12 && \
    # キャッシュを削除
    yum clean all && \
    # JST
    touch /etc/sysconfig/clock && \
    echo 'ZONE="Asia/Tokyo"' >> /etc/sysconfig/clock&& \
    echo 'UTC=false' >> /etc/sysconfig/clock && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    # locale
    touch /etc/sysconfig/i18n && \
    echo 'ja_JP.UTF-8' >> /etc/sysconfig/i18n

COPY ./rds_logical_backup.sh /root/
RUN chmod 755 /root/rds_logical_backup.sh
RUN mkdir /root/logs
ENTRYPOINT ["/bin/bash"]
# ENTRYPOINT ["/root/rds_logical_backup.sh"]
