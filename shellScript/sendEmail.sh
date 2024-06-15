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

echo "#VVVVVVVV 数据库备份情况每日报告 VVVVVVVV"
# 获取日期
today=$(date +%Y-%m-%d)
yesterday=$(date -d "@$(( $(date +%s) - 86400 ))" +%Y-%m-%d)
day_before_yesterday=$(date -d "@$(( $(date +%s) - 172800 ))" +%Y-%m-%d)

# 文件名
TodayLogFilename="DailyReport-$today.log"
YesterdayLogFileName="DailyReport-$yesterday.log"
DayBeforeYesterdayLogFileName="DailyReport-$day_before_yesterday.log"

# 删除前天的日志文件
if [ -f "$DayBeforeYesterdayLogFileName" ]; then
    rm -f "$DayBeforeYesterdayLogFileName"
fi

# 如果今天的日志文件还不存在，则创建今天的日志文件并写入初始内容
if [ ! -f "$TodayLogFilename" ]; then
    echo -e "Daily Report of $today" > "$TodayLogFilename"
fi


# 定义插入内容的函数，在文件的第2行之前插入内容
insert_content_at_beginning_2nd_line() {
    local file="$1"
    local content="$2"
    
    #原用 sed 的写法一直出各种错，故改用 awk
    awk -v content="$content" 'NR==1{print; print content; next}1' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}


# 获取当前时间和 atq 输出                                        
current_time=$(printf "Now: %s   atq待执行job:" "$(date +"%H:%M")")     
#将 atq_output 的每行开头都添加9个空格
atq_output="$(atq | sed 's/^/         /')
"

# 将当前时间和 atq 输出拼接成一个内容块                         
# 赋给log_snippet即本次执行将要输出的一小段log                  
log_snippet="
$current_time
$atq_output"                    


# 获取 /data/one-api.db 文件的最近修改日期时间
DBFileModifyTimestamp=$(stat -c %Y /data/one-api.db)
DBFileLastModifyDatetime=$(date -d "@$DBFileModifyTimestamp" "+%Y-%m-%d %H:%M:%S")
# 输出 DB 文件的最近修改日期时间并添加到今天的日志文件中
log_snippet="${log_snippet}DB文件最近修改于：$DBFileLastModifyDatetime"   


# 当前时间减去20分钟的时间戳
time_20_minutes_ago_timestamp=$(date -d @$(( $(date +%s) - 1200 )) +%s)

# 构建邮件正文的昨天的报告部分
EmailBodyText_YesterdayPart="\n\n\n\n-------==== 昨天的报告 ====-------\n\n"
if [ -f "$YesterdayLogFileName" ]; then
    EmailBodyText_YesterdayPart="$EmailBodyText_YesterdayPart$(cat "$YesterdayLogFileName")"
else
    EmailBodyText_YesterdayPart="$EmailBodyText_YesterdayPart(无昨日报告文件)"
fi

######## gpt-4o 重构的代码 #######
send_email() {
    local subject="$1"
    local email_body="$2"
    local attachment="$3"

    if [ -n "$attachment" ]; then
        echo "#发邮件 并附DB备份文件"
        echo -e "Send on: $(date +"%Y-%m-%d %H:%M") by key1api-web app in a docker container. \n$email_body\n\n---- The DB file is compressed and encrypted. ----" | mutt -s "$subject" -a "$attachment" -- LLC.Good.House@gmail.com
    else
        echo "#发邮件 不附DB备份文件"
        echo -e "Send on: $(date +"%Y-%m-%d %H:%M") by key1api-web app in a docker container. \n$email_body\n\n---- Since no change, so the DB backup file is not included. ----" | mutt -s "$subject" LLC.Good.House@gmail.com
    fi
}

update_log_and_send_email() {
    local log_message="$1"
    local subject="$2"
    local attachment="$3"

    log_snippet="${log_snippet}, ${log_message}"
    insert_content_at_beginning_2nd_line "$TodayLogFilename" "$log_snippet"  #调用函数将内容插入到 今天的日志文件的最前面第2行
    EmailBodyText=$(cat "$TodayLogFilename")"$EmailBodyText_YesterdayPart"
    send_email "$subject" "$EmailBodyText" "$attachment"
}

if [ "$DBFileModifyTimestamp" -gt "$time_20_minutes_ago_timestamp" ]; then
    update_log_and_send_email "最近20分钟 有被修改。邮件发：备份报告 + DB文件附件" "one-api.db and Backup Report" "/data/Encrypted_Compressed_SQLiteDB.zip"
else
    update_log_and_send_email "最近20分钟 无变化。邮件发：仅备份报告" "one-api.db and Backup Report" ""
fi

echo "#AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

echo "# 记录结束时间"
end_time=$(date +%s)

echo "# 计算并显示这一次 sendEmail 的耗时"
elapsed_time=$((end_time - start_time))
echo "sendEmail.sh 脚本执行共耗时：$elapsed_time 秒"
