echo "执行：获取数据库并部署 = GetDB_and_Restore.sh 脚本 ..."
echo "容器重启动后one-api.db文件还未创建，应不存在，获取SQLite DB文件，以恢复原数据"
if [ ! -f /data/one-api.db ]; then
    wget -O /data/Encrypted_Compressed_SQLiteDB.zip "https://raw.githubusercontent.com/bingjiw/static_key.wewegpt.com/main/SQLite_DB_file/Encrypted_Compressed_SQLiteDB.zip"
    echo "Encrypted_Compressed_SQLiteDB.zip文件从Github下载成功"
    # 安装解压缩工具
    apk add unzip

    # 解压缩文件，使用从参数 $1 传入的密码
    if unzip -P "$1" /data/Encrypted_Compressed_SQLiteDB.zip -d /data/; then
        echo "Encrypted_Compressed_SQLiteDB.zip文件解压缩成功，one-api启动时应可以发现one-api.db数据库文件并使用它加载原有数据。"
    else
        echo "Encrypted_Compressed_SQLiteDB.zip文件解压缩失败!!!(可能是由于传入的密码错误)"
        exit 1
    fi
    
else
    echo "one-api.db 文件已经存在，无需下载"
fi
echo "--------------------------------"
