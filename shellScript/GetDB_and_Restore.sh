echo "--------------- 获取数据库并恢复DB数据 GetDB_and_Restore.sh ---------------"
echo "从Github获取SQLite DB文件，若本脚本执行于容器刚刚重启动后，则one-api.db文件还未创建，应不存在"
if [ ! -f /data/one-api.db ]; then

    # 下载文件并覆盖已存在的文件
    wget -O /data/Encrypted_Compressed_SQLiteDB.zip "https://raw.githubusercontent.com/bingjiw/static4wewe/main/SQLite_DB_file/Encrypted_Compressed_SQLiteDB.zip"
    echo "Encrypted_Compressed_SQLiteDB.zip文件从Github下载成功"

    # 安装解压缩工具
    apk add unzip

    # 解压缩文件，使用从 环境变量 $SQLITE_DB_FILE_COMPRESS_PASSWORD 传入的密码
    if unzip -P "$SQLITE_DB_FILE_COMPRESS_PASSWORD" /data/Encrypted_Compressed_SQLiteDB.zip -d /data/; then
        echo "Encrypted_Compressed_SQLiteDB.zip文件解压缩成功，one-api启动时应可以发现one-api.db数据库文件并使用它加载原有数据。"
    else
        echo "Encrypted_Compressed_SQLiteDB.zip文件解压缩失败!!!(可能是由于从环境变量传入的密码错误)"
        exit 1
    fi
    
else
    echo "》》》》》》》》one-api.db 文件已经存在，无需下载。没有改动已有的 one-api.db 文件"
fi
echo "################# 完成 获取数据库并恢复DB数据 #################"
