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

echo "# 配置 msmtp, 若无则写入 /root/.msmtprc"
if [ ! -f /root/.msmtprc ]; then
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
else
    echo "# msmtp 配置文件已存在，不用重新写入"
fi

echo "# 配置 mutt，若无则写入 /root/.muttrc，以使用 msmtp 发送邮件"
if [ ! -f /root/.muttrc ]; then
    cat > /root/.muttrc <<EOL
set sendmail="/usr/bin/msmtp"
set use_from=yes
set realname="at command - auto job - app of key1api-web"
set from=xiaorong.boy@icloud.com
set envelope_from=yes
EOL
else
    echo "# mutt 配置文件已存在，无需重新写入"
fi

echo "#vvvvvvvv 数据库备份情况每日报告 vvvvvvvv"
# 获取日期
today=$(date +%Y-%m-%d)
yesterday=$(date -d "yesterday" +%Y-%m-%d)
day_before_yesterday=$(date -d "2 days ago" +%Y-%m-%d)

# 文件名
TodayLogFilename="DailyReport-$today.log"
YesterdayLogFileName="DailyReport-$yesterday.log"
DayBeforeYesterdayLogFileName="DailyReport-$day_before_yesterday.log"

# 删除前天的日志文件
if [ -f "$DayBeforeYesterdayLogFileName" ]; then
    rm -f "$DayBeforeYesterdayLogFileName"
fi

# 创建今天的日志文件并写入初始内容
if [ ! -f "$TodayLogFilename" ]; then
    echo "Daily Report of $today" > "$TodayLogFilename"
fi

# 执行 atq 并将输出添加到今天的日志文件中
atq >> "$TodayLogFilename"

# 获取 /data/one-api.db 文件的最近修改日期时间
DBFileLastModifyDatetime=$(stat -c %y /data/one-api.db)

# 输出 DB 文件的最近修改日期时间并添加到今天的日志文件中
echo "DB文件最近修改日期时间：$DBFileLastModifyDatetime" >> "$TodayLogFilename"

# 当前时间减去20分钟的时间戳
time_20_minutes_ago_timestamp=$(date -d @$(( $(date +%s) - 1200 )) +%s)

# 获取 DB 文件的修改时间戳
DBFileModifyTimestamp=$(stat -c %Y /data/one-api.db)

# 构建邮件正文
EmailBodyText=$(cat "$TodayLogFilename")
EmailBodyText="$EmailBodyText\n\n---- 昨天的报告 ----\n"
if [ -f "$YesterdayLogFileName" ]; then
    EmailBodyText="$EmailBodyText$(cat "$YesterdayLogFileName")"
else
    EmailBodyText="$EmailBodyText(无昨日报告文件)"
fi

# 比较DB文件的修改时间与当前时间减去20分钟
if [ "$DBFileModifyTimestamp" -gt "$time_20_minutes_ago_timestamp" ]; then
    echo "DB文件在最近20分钟内 有被修改,发邮件：备份报告+DB文件" >> "$TodayLogFilename"

    echo "#发邮件 并附DB备份文件"
    echo -e "Send on: $(date) by key1api-web app in a docker container. \n$EmailBodyText\nThe DB file is compressed and encrypted." | mutt -s "one-api.db and Backup Report" -a /data/Encrypted_Compressed_SQLiteDB.zip -- LLC.Good.House@gmail.com
else
    echo "DB文件在最近20分钟内 无变化,发邮件：仅备份报告" >> "$TodayLogFilename"
    
    echo "#发邮件 不附DB备份文件"
    echo -e "Send on: $(date) by key1api-web app in a docker container. \n$EmailBodyText\nThe DB backup file is not included." | mutt -s "one-api.db and Backup Report" LLC.Good.House@gmail.com
fi

echo "#===================================="

echo "# 记录结束时间"
end_time=$(date +%s)

echo "# 计算并显示这一次 sendEmail 的耗时"
elapsed_time=$((end_time - start_time))
echo "sendEmail.sh 脚本执行共耗时：$elapsed_time 秒"
