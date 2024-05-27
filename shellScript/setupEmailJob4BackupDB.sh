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

echo "############### 建 400 个 at job 每6个小时 发SQLite DB邮件以备份"

echo "###### 1. 安装 at 和 atd"
apk add at

echo "###### 2. 启动 atd 服务"
atd

echo "###### 3. 创建并运行设置 at 命令"
echo "## 循环设置 4000 条 at 命令，每6小时执行一次，一天4次，共1000天（约2.7年）"
for i in $(seq 0 3999); do
  # 计算执行时间
  HOURS=$((i * 6))
  
  # 设置邮件标题
  EMAIL_TITLE="$i at👑job: one-api.db for backup"
  
  # 设置 at 命令
  echo -e "$i of 4000次执行 \n\n send on: $(date) \n\n by key1api-web app in container" | mutt -s "$EMAIL_TITLE" -a /data/one-api.db -- LLC.Good.House@gmail.com | at now + $HOURS hours

  # 4000次，每执行完一次，显示一个小点点，效果...........
  echo -n "."
done

echo -e "\n############### all done."

#原命令，现已放入循环中执行
#echo -e "send on: $(date) \n\n\n by key1api-web app in container " | mutt -s "👑cron👑job: one-api.db for backup" -a /data/one-api.db -- LLC.Good.House@gmail.com
