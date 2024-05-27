#!/bin/sh

echo "安装：发带附件的邮件 的工具"
echo "若mutt没有安装，就安装mutt。若msmtp没有安装，就安装msmtp。"

# 检查并安装 mutt
if ! command -v mutt >/dev/null 2>&1; then
    echo "mutt 未安装，正在安装..."
    apk add mutt
else
    echo "mutt 已安装"
fi

# 检查并安装 msmtp
if ! command -v msmtp >/dev/null 2>&1; then
    echo "msmtp 未安装，正在安装..."
    apk add msmtp
else
    echo "msmtp 已安装"
fi

echo "# 配置 msmtp"
cat > /root/.msmtprc <<EOL
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /root/.msmtp.log

account        default
host           smtp.mail.me.com
port           587
from           xiaorong.boy@icloud.com
user           xiaorong.boy@icloud.com
passwordeval   echo \$SMTP_PASSWORD
EOL

echo "# 确保 msmtprc 文件权限"
chmod 600 /root/.msmtprc

echo "# 配置 mutt 使用 msmtp 发送邮件"
cat > /root/.muttrc <<EOL
set sendmail="/usr/bin/msmtp"
set use_from=yes
set realname="cron job of app of key1api-web"
set from=xiaorong.boy@icloud.com
set envelope_from=yes
EOL

# 环境变量中设置 SMTP 密码, 移到执行本script之前的run command中执行
# export SMTP_PASSWORD="--will be set before RUN this script--"

echo "# 建cron job 每天凌晨3:20 使用 mutt 发送带附件的邮件"
echo "send from key1api-web app in container on: $(date)" | mutt -s "👑cron👑job: one-api.db for backup" -a /data/one-api.db -- LLC.Good.House@gmail.com
