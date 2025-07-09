#!/system/bin/sh

MODDIR=${0%/*}
CONFIG_FILE="${MODDIR}/config.yaml"
MODULE_PROP="${MODDIR}/module.prop"
VNT_CLI="${MODDIR}/bin/vnt-cli"

update_module_description() {
    local status_message=$1
    sed -i "/^description=/c\description=[状态]${status_message}" ${MODULE_PROP}
}

while true; do
    if ls $MODDIR | grep -q "disable"; then
        update_module_description "关闭中.."
        if pgrep -f 'vnt-cli' >/dev/null; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") 进程已存在，正在关闭 ..."
            pkill vnt-cli # 关闭进程
            update_module_description "已关闭！"
        fi
    else
        if ! pgrep -f 'vnt-cli' >/dev/null; then
            update_module_description "开始启动..."
            echo "$(date "+%Y-%m-%d %H:%M:%S") 开始启动 ..."

            if [ ! -s "$CONFIG_FILE" ]; then
                update_module_description "错误：config.yaml配置文件不存在或为空,请修改 ${MODDIR}/config.yaml"
                sleep 3s
                continue
            fi
            # 这是启动命令 使用了 -f 参数 指定配置文件 如果修改下方命令为参数启动 则需要删除上方的对配置文件为空的判断语句
            ${VNT_CLI} -f "${CONFIG_FILE}" > "${MODDIR}/log.log" 2>&1 &

            sleep 3s # 等待vnt-cli启动完成
            if pgrep -f 'vnt-cli' >/dev/null; then
                ip rule | grep -q "from all lookup main" || {
                    if ip rule add from all lookup main; then
                        update_module_description "已添加路由！"
                        echo "$(date "+%Y-%m-%d %H:%M:%S") 已添加路由" >> "${MODDIR}/log.log"
                    else
                        update_module_description "添加路由失败！"
                        echo "$(date "+%Y-%m-%d %H:%M:%S") 添加路由失败！可能导致无法访问虚拟局域网内其他客户端" >> "${MODDIR}/log.log"
                    fi
                }
	 	        update_module_description "运行中..."
            else
                update_module_description "运行失败，请查看 ${MODDIR}/log.log 失败原因。"
            fi

        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") 进程已存在"
        fi
    fi
    
    sleep 3s # 暂停3秒后再次执行循环
    # 判断 log.log 是否超过 5MB，超过则清空
    if [ -f "${MODDIR}/log.log" ]; then
         # 不确定安卓是否有效
        log_size=$(stat -c%s "${MODDIR}/log.log")  # 获取文件大小（单位：字节）
        if [ "$log_size" -gt 5242880 ]; then  # 5MB = 5 * 1024 * 1024 = 5242880 字节
            echo "$(date "+%Y-%m-%d %H:%M:%S") 日志文件超过5MB，已自动清空" > "${MODDIR}/log.log"
        fi
    fi
done
