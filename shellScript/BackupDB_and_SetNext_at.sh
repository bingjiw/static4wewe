#!/bin/sh

# 安装at命令
apk add at

# 启动atd服务
atd start

# 将BackupDB.sh脚本设置为可执行
chmod +x /data/BackupDB.sh

# 以最低CPU优先级执行BackupDB.sh
nice -n 19 /data/BackupDB.sh

# 设定20分钟后执行BackupDB_and_SetNext_at.sh脚本
echo "/data/BackupDB_and_SetNext_at.sh" | at now + 20 minutes

