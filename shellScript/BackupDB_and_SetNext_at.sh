#!/bin/sh

echo "---------- 执行 BackupDB_and_SetNext_at.sh -----------"

echo "# 检查是否已安装at命令，如果未安装则进行安装"
if ! command -v at &> /dev/null; then
    echo "at命令未安装，正在安装..."
    apk add at
else
    echo "at命令已安装"
fi

echo "# 检查atd服务是否已启动，如果未启动则启动服务"
if ! pgrep -x "atd" > /dev/null; then
    echo "atd服务未启动，正在启动..."
    atd start
else
    echo "atd服务已启动"
fi

echo "# 将BackupDB.sh脚本设置为可执行"
chmod +x /data/BackupDB.sh

echo "# 设定20分钟后执行BackupDB_and_SetNext_at.sh脚本"
echo "/data/BackupDB_and_SetNext_at.sh" | at now + 20 minutes

echo "# 以最低CPU优先级执行BackupDB.sh"
nice -n 19 /data/BackupDB.sh
