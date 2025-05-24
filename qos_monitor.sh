#!/bin/sh
# QoS 流量控制监控脚本 - 直观显示网络状态

WAN_IF="eth1"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 清屏函数
clear_screen() {
    printf '\033[2J\033[H'
}

# 格式化字节数
format_bytes() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        printf "%.2fGB" $(echo "scale=2; $bytes/1073741824" | bc)
    elif [ $bytes -gt 1048576 ]; then
        printf "%.2fMB" $(echo "scale=2; $bytes/1048576" | bc)
    elif [ $bytes -gt 1024 ]; then
        printf "%.2fKB" $(echo "scale=2; $bytes/1024" | bc)
    else
        printf "%dB" $bytes
    fi
}

# 格式化速率
format_rate() {
    local rate=$1
    if echo "$rate" | grep -q "Mbit"; then
        echo "$rate" | sed 's/Mbit/Mbps/'
    elif echo "$rate" | grep -q "Kbit"; then
        echo "$rate" | sed 's/Kbit/Kbps/'
    else
        echo "$rate"
    fi
}

# 判断状态颜色
get_status_color() {
    local dropped=$1
    local overlimits=$2
    local backlog=$3
    
    if [ $dropped -gt 1000 ] || [ $overlimits -gt 10000 ] || [ $backlog -gt 50000 ]; then
        echo "$RED"
    elif [ $dropped -gt 100 ] || [ $overlimits -gt 1000 ] || [ $backlog -gt 10000 ]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# 获取QoS统计信息
get_qos_stats() {
    local interface=$1
    local direction=$2
    
    # 获取TBF统计
    local tbf_stats=$(tc -s qdisc show dev $interface | grep -A 3 "qdisc tbf")
    local fq_stats=$(tc -s qdisc show dev $interface | grep -A 5 "qdisc fq_codel")
    
    if [ -z "$tbf_stats" ]; then
        echo "${RED}未找到 $direction 队列配置${NC}"
        return
    fi
    
    # 提取关键数据
    local rate=$(echo "$tbf_stats" | grep "qdisc tbf" | grep -o "rate [^ ]*" | cut -d' ' -f2)
    local sent_bytes=$(echo "$tbf_stats" | grep "Sent" | grep -o "Sent [0-9]*" | cut -d' ' -f2)
    local sent_packets=$(echo "$tbf_stats" | grep "Sent" | grep -o "[0-9]* pkt" | cut -d' ' -f1)
    local dropped=$(echo "$tbf_stats" | grep "dropped" | grep -o "dropped [0-9]*" | cut -d' ' -f2)
    local overlimits=$(echo "$tbf_stats" | grep "overlimits" | grep -o "overlimits [0-9]*" | cut -d' ' -f2)
    local backlog_bytes=$(echo "$tbf_stats" | grep "backlog" | grep -o "backlog [0-9]*b" | cut -d' ' -f2 | sed 's/b//')
    local backlog_packets=$(echo "$tbf_stats" | grep "backlog" | grep -o "[0-9]*p" | sed 's/p//')
    
    # FQ_CODEL 特定信息
    local fq_dropped=$(echo "$fq_stats" | grep "Sent" | grep -o "dropped [0-9]*" | cut -d' ' -f2)
    local new_flows=$(echo "$fq_stats" | grep "new_flow_count" | grep -o "new_flow_count [0-9]*" | cut -d' ' -f2)
    local memory_used=$(echo "$fq_stats" | grep "memory_used" | grep -o "memory_used [0-9]*" | cut -d' ' -f2)
    
    # 默认值处理
    [ -z "$dropped" ] && dropped=0
    [ -z "$overlimits" ] && overlimits=0
    [ -z "$backlog_bytes" ] && backlog_bytes=0
    [ -z "$backlog_packets" ] && backlog_packets=0
    [ -z "$fq_dropped" ] && fq_dropped=0
    [ -z "$new_flows" ] && new_flows=0
    [ -z "$memory_used" ] && memory_used=0
    
    # 状态判断
    local status_color=$(get_status_color $dropped $overlimits $backlog_bytes)
    
    printf "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
    printf "${BLUE}  %s 方向流量控制状态${NC}\n" "$direction"
    printf "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
    printf "  限制速率: ${YELLOW}%s${NC}\n" "$(format_rate $rate)"
    printf "  总流量:   ${GREEN}%s${NC} (%s 包)\n" "$(format_bytes $sent_bytes)" "$sent_packets"
    printf "  丢包数:   ${status_color}%s${NC}\n" "$dropped"
    printf "  超限次数: ${status_color}%s${NC}\n" "$overlimits"
    printf "  队列积压: ${status_color}%s (%s 包)${NC}\n" "$(format_bytes $backlog_bytes)" "$backlog_packets"
    
    if [ ! -z "$new_flows" ] && [ "$new_flows" != "0" ]; then
        printf "  新流计数: ${GREEN}%s${NC}\n" "$new_flows"
    fi
    
    if [ ! -z "$memory_used" ] && [ "$memory_used" != "0" ]; then
        printf "  内存使用: ${GREEN}%s${NC}\n" "$(format_bytes $memory_used)"
    fi
    
    # 状态评估
    printf "  状态评估: "
    if [ $dropped -gt 1000 ] || [ $overlimits -gt 10000 ]; then
        printf "${RED}需要调整 - 丢包/超限过多${NC}\n"
    elif [ $backlog_bytes -gt 50000 ]; then
        printf "${YELLOW}轻微拥塞 - 队列积压较多${NC}\n"
    else
        printf "${GREEN}运行良好${NC}\n"
    fi
    printf "\n"
}

# 主监控循环
main_monitor() {
    while true; do
        clear_screen
        
        printf "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}\n"
        printf "${GREEN}║                    QoS 流量控制实时监控                        ║${NC}\n"
        printf "${GREEN}║                   $(date '+%Y-%m-%d %H:%M:%S')                   ║${NC}\n"
        printf "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}\n\n"
        
        # 检查QoS是否启用
        if ! tc qdisc show dev $WAN_IF | grep -q "qdisc tbf"; then
            printf "${RED}❌ QoS 未启用或配置错误${NC}\n"
            printf "${YELLOW}请先运行 ./fq.sh 启用QoS${NC}\n"
            exit 1
        fi
        
        # 显示上传统计
        get_qos_stats $WAN_IF "上传"
        
        # 显示下载统计
        if ip link show ifb0 >/dev/null 2>&1; then
            get_qos_stats ifb0 "下载"
        else
            printf "${RED}❌ 下载队列 (ifb0) 未配置${NC}\n\n"
        fi
        
        # 显示建议
        printf "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
        printf "${BLUE}  优化建议${NC}\n"
        printf "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
        printf "  🔹 ${GREEN}绿色${NC}: 运行良好，无需调整\n"
        printf "  🔸 ${YELLOW}黄色${NC}: 轻微问题，可考虑微调\n" 
        printf "  🔴 ${RED}红色${NC}: 需要调整带宽或算法参数\n"
        printf "\n"
        printf "  ${YELLOW}按 Ctrl+C 退出监控${NC}\n"
        
        sleep 2
    done
}

# 一次性显示模式
show_once() {
    clear_screen
    printf "${GREEN}QoS 状态快照 - $(date '+%Y-%m-%d %H:%M:%S')${NC}\n\n"
    
    get_qos_stats $WAN_IF "上传"
    
    if ip link show ifb0 >/dev/null 2>&1; then
        get_qos_stats ifb0 "下载"
    fi
}

# 参数处理
case "$1" in
    "once"|"-o")
        show_once
        ;;
    "help"|"-h"|"--help")
        echo "QoS 监控脚本使用说明:"
        echo "  $0          - 实时监控模式 (默认)"
        echo "  $0 once     - 显示一次状态快照"
        echo "  $0 help     - 显示此帮助信息"
        ;;
    *)
        main_monitor
        ;;
esac
