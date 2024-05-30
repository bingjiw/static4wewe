#!/bin/sh

echo "#----执行 BackupDB.sh----"
echo "#上级的调用者会以最低CPU优先级执行本BackupDB.sh"

echo "#先删除上次的压缩文件 /data/Encrypted_Compressed_SQLiteDB.zip"
rm -f /data/Encrypted_Compressed_SQLiteDB.zip

echo "#检查 zip 是否已安装"
if ! command -v zip > /dev/null 2>&1; then
    echo "#安装 zip 压缩工具"
    apk add --no-cache zip 
else
    echo "#zip 已经安装"
fi

echo "#加密并压缩 one-api.db 文件"
cd /data
zip -e -P "$SQLITE_DB_FILE_COMPRESS_PASSWORD" Encrypted_Compressed_SQLiteDB.zip one-api.db

echo "#调用 sendEmail.sh 把压缩的DB文件发邮件给管理员"
/data/sendEmail.sh
