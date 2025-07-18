# 備份VeraCrypt的B磁盤，並用openssl加密壓縮檔案
# 设置脚本编码为 UTF-8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 定义备份文件名前缀
$backupPrefix = "Xshell"

# 設定變量
$sourceDir = "E:\CloudStorage\SyncJJ\_4pc\etc\NetSarang6"
# 定义排除的目录或文件
$excludeDir = "E:\CloudStorage\Dropbox\d02.workpub\etc\NetSarang6\NonExist"  # 要排除的目录

$backupDir = "N:\backup\usual_backup\Xshell"
$encryptionKey = "W:\home\.private.j\jj_encryption.key"

# 定义 OpenSSL 可执行文件路径
$opensslPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"

# 獲取當前日期，格式為YYYYMMDD
$date = Get-Date -Format "yyyyMMdd_HHmm"

# 生成壓縮文件名
$zipFilename = "JJ_${backupPrefix}_$date.zip"
$zipFilepath = Join-Path $backupDir $zipFilename
# 確保 7-Zip 的可執行文件在 PATH 中
$env:Path += ";C:\Program Files\7-Zip"

# 記錄備份開始時間
$startTime = Get-Date

# 壓縮文件

$zipCommand = "7z a -tzip `"$zipFilepath`" `"$sourceDir`" -xr!`"$excludeDir`""

Invoke-Expression $zipCommand


# 生成加密文件名
#$encFilename = "JJ_Xshell_$date.zip.enc"
#$encFilepath = Join-Path $backupDir $encFilename

# 使用OpenSSL加密壓縮文件
#& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$zipFilepath" -out "$encFilepath" -pass file:"$encryptionKey"

#解密
# & "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 -in "$encFilepath" -out "$zipFilepath" -pass file:"$encryptionKey"

# 檢查壓縮是否成功
if ($LASTEXITCODE -ne 0) {
    Write-Host "壓縮失敗！"
    exit $LASTEXITCODE
}

# 刪除原始壓縮文件
#Remove-Item $zipFilepath

# 記錄備份結束時間
$endTime = Get-Date

# 删除旧的备份文件，只保留最新的5份
$maxBackupCount = 5
$backupFiles = Get-ChildItem -Path $backupDir -Filter "$backupPrefix_*.zip" | Sort-Object -Property LastWriteTime -Descending

if ($backupFiles.Count -gt $maxBackupCount) {
    $filesToDelete = $backupFiles | Select-Object -Skip $maxBackupCount
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName
    }
}

# 計算耗用時長
$duration = $endTime - $startTime
$formattedDuration = [string]::Format("{0:D2}h {1:D2}m {2:D2}s", $duration.Hours, $duration.Minutes, $duration.Seconds)

# 要发送的消息内容（使用 UTF-8 编码）
$tg_text = "JJWS2 ${backupPrefix} backuped!`n完成日期: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))`n耗用时长: $formattedDuration"

Write-Host "$tg_text"

# 使用 curl 发送消息到 Telegram
$CHAT_A00_JJ_INFO="-1002061622893"
$JJ01BOT_TOKEN="1124675180:AAHXnQ03W_2B_lIcR2FRe4DrUopyXaXShYE"
$TELEGRAM_URL="https://api.telegram.org/bot$JJ01BOT_TOKEN/sendMessage"

$headers = @{
    "Content-Type" = "application/json; charset=utf-8"
}

# 构建请求体（消息内容）
$body = @{
    chat_id = $CHAT_A00_JJ_INFO
    text = $tg_text
    parse_mode = ""
    disable_notification = $true
} | ConvertTo-Json -Depth 3



# 发送 POST 请求到 Telegram
$params = @{
    Uri = $TELEGRAM_URL
    Method = 'Post'
    ContentType = 'application/json; charset=utf-8'
    Body = $body
}
$response = Invoke-RestMethod @params
