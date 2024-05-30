#!/bin/sh

echo "#--执行 sendEmail.sh--"

echo "# 记录脚本的开始时间"
start_time=$(date +%s)

if [ -z "$SMTP_PASSWORD" ]; then
    echo "无环境变量 SMTP_PASSWORD（SMTP发信密码）无法发信。"
    exit 1
fi

echo "安装：发带附件的邮件 的工具"
echo "若mutt没有安装，就安装mutt。若msmtp没有安装，就安装msmtp。"

echo "# 检查并安装 mutt"
if ! command -v mutt >/dev/null 2>&1; then
    echo "mutt 未安装，正在安装..."
    apk add mutt
else
    echo "mutt 已安装"
fi

echo "# 检查并安装 msmtp"
if ! command -v msmtp >/dev/null 2>&1; then
    echo "msmtp 未安装，正在安装..."
    apk add msmtp
else
    echo "msmtp 已安装"
fi

echo "# 配置 msmtp, 写/root/.msmtprc"
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
passwordeval   echo ${SMTP_PASSWORD}
EOL

echo "# 确保 msmtprc 文件权限"
chmod 600 /root/.msmtprc

echo "# 配置 mutt，写/root/.muttrc，以使用 msmtp 发送邮件"
cat > /root/.muttrc <<EOL
set sendmail="/usr/bin/msmtp"
set use_from=yes
set realname="at command - auto job - app of key1api-web"
set from=xiaorong.boy@icloud.com
set envelope_from=yes
EOL

echo "#发邮件"
echo -e "Send on: $(date) \n\n by key1api-web app in container. \n\n The DB file is compressed and encrypted." | mutt -s "one-api.db for backup" -a /data/Encrypted_Compressed_SQLiteDB.zip -- LLC.Good.House@gmail.com

echo "# 记录结束时间"
end_time=$(date +%s)

echo "# 计算并显示这一次 sendEmail 的耗时"
elapsed_time=$((end_time - start_time))
echo "sendEmail.sh 脚本执行共耗时：$elapsed_time 秒"
