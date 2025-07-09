#!/data/adb/magisk/busybox sh

MODDIR=${0%/*}

# 赋予执行权限
chmod -R 755 ${MODDIR}/*

# 等待系统启动成功
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5s
done

# 防止系统挂起
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock

sed -i 's/\(description=\)[^"]*/\1[状态]已关闭/' $MODDIR/module.prop

if [ ! -e /dev/net/tun ]; then
    if [ ! -d /dev/net ]; then
        mkdir -p /dev/net
    fi

    ln -s /dev/tun /dev/net/tun
fi

sleep 3s

"${MODDIR}/vnt-run.sh" &

while [ ! -f ${MODDIR}/disable ]; do 
    sleep 2
done

pkill vnt-cli
