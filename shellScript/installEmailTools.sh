#!/bin/sh

echo "安装：发带附件的邮件 的工具"
echo "若mutt没有安装，就安装mutt。若ssmtp没有安装，就安装ssmtp。"

# 检查并安装 mutt
if ! command -v mutt >/dev/null 2>&1; then
    echo "mutt 未安装，正在安装..."
    apk add mutt
else
    echo "mutt 已安装"
fi

# 检查并安装 ssmtp
if ! command -v ssmtp >/dev/null 2>&1; then
    echo "ssmtp 未安装，正在安装..."
    apk add ssmtp
else
    echo "ssmtp 已安装"
fi
