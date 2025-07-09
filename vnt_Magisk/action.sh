#!/data/adb/magisk/busybox sh
MODPATH=${0%/*}

PID=$(pgrep vnt-cli)

if [ -z "$PID" ]; then
    echo "VNT 进程未找到"
else
    kill $PID
    echo "已结束进程 (PID: $PID)"
fi