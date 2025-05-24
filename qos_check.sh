#!/bin/sh
# 简化的 QoS 状态检查脚本

WAN_IF="eth1"

printf "QoS 状态检查 - $(date '+%H:%M:%S')\n"
printf "========================================\n"

# 检查上传队列
echo "【上传队列 - $WAN_IF】"
upload_stats=$(tc -s qdisc show dev $WAN_IF | grep -A 3 "qdisc tbf")
if [ -n "$upload_stats" ]; then
    rate=$(echo "$upload_stats" | grep "rate" | grep -o "rate [^b]*" | cut -d' ' -f2)
    dropped=$(echo "$upload_stats" | grep "dropped" | grep -o "dropped [0-9]*" | cut -d' ' -f2)
    overlimits=$(echo "$upload_stats" | grep "overlimits" | grep -o "overlimits [0-9]*" | cut -d' ' -f2)
    
    printf "  速率限制: %s\n" "$rate"
    printf "  丢包: %s | 超限: %s\n" "${dropped:-0}" "${overlimits:-0}"
    
    if [ "${dropped:-0}" -gt 100 ] || [ "${overlimits:-0}" -gt 1000 ]; then
        printf "  状态: ⚠️  需要关注\n"
    else
        printf "  状态: ✅ 正常\n"
    fi
else
    printf "  状态: ❌ 未配置\n"
fi

echo ""

# 检查下载队列
echo "【下载队列 - ifb0】"
if ip link show ifb0 >/dev/null 2>&1; then
    download_stats=$(tc -s qdisc show dev ifb0 | grep -A 3 "qdisc tbf")
    if [ -n "$download_stats" ]; then
        rate=$(echo "$download_stats" | grep "rate" | grep -o "rate [^b]*" | cut -d' ' -f2)
        dropped=$(echo "$download_stats" | grep "dropped" | grep -o "dropped [0-9]*" | cut -d' ' -f2)
        overlimits=$(echo "$download_stats" | grep "overlimits" | grep -o "overlimits [0-9]*" | cut -d' ' -f2)
        backlog=$(echo "$download_stats" | grep "backlog" | grep -o "backlog [0-9]*b" | cut -d' ' -f2 | sed 's/b//')
        
        printf "  速率限制: %s\n" "$rate"
        printf "  丢包: %s | 超限: %s | 积压: %s字节\n" "${dropped:-0}" "${overlimits:-0}" "${backlog:-0}"
        
        if [ "${dropped:-0}" -gt 1000 ] || [ "${overlimits:-0}" -gt 10000 ] || [ "${backlog:-0}" -gt 50000 ]; then
            printf "  状态: ⚠️  需要调整\n"
        else
            printf "  状态: ✅ 正常\n"
        fi
    else
        printf "  状态: ❌ 未配置\n"
    fi
else
    printf "  状态: ❌ ifb0 接口不存在\n"
fi

echo ""
printf "快速命令:\n"
printf "  详细监控: ./qos_monitor.sh\n"
printf "  停止QoS:  ./fq.sh stop\n"
