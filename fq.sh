#!/bin/sh
# OpenWrt Pure fq_codel Gaming QoS - 极简版本
# 最大化利用 fq_codel 的内置智能特性

WAN_IF="eth1"
UPLOAD_MBPS=50    # 实际上传速度
DOWNLOAD_MBPS=100 # 实际下载速度

# fq_codel 能很好处理缓冲区膨胀，可以设置更接近实际速度
UPLOAD_KBPS=$((UPLOAD_MBPS * 950))   # 95%
DOWNLOAD_KBPS=$((DOWNLOAD_MBPS * 950)) # 95%

echo "启用fq_codel QoS: $WAN_IF 上传${UPLOAD_KBPS}kbps 下载${DOWNLOAD_KBPS}kbps"

# 清理现有配置
tc qdisc del dev $WAN_IF root 2>/dev/null
tc qdisc del dev $WAN_IF ingress 2>/dev/null
tc qdisc del dev ifb0 root 2>/dev/null
ip link del ifb0 2>/dev/null

# 配置上传队列
tc qdisc add dev $WAN_IF root handle 1: tbf rate ${UPLOAD_KBPS}kbit latency 25ms burst 15k
tc qdisc add dev $WAN_IF parent 1: fq_codel target 1ms interval 10ms flows 1024 quantum 300

# 配置下载队列
modprobe ifb
ip link add name ifb0 type ifb 2>/dev/null
ip link set dev ifb0 up
tc qdisc add dev $WAN_IF ingress
tc filter add dev $WAN_IF parent ffff: protocol all u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb0
tc qdisc add dev ifb0 root handle 1: tbf rate ${DOWNLOAD_KBPS}kbit latency 25ms burst 15k
tc qdisc add dev ifb0 parent 1: fq_codel target 1ms interval 10ms flows 1024 quantum 300

echo "QoS配置完成"
echo "监控: watch -n 1 'tc -s qdisc show dev $WAN_IF && echo && tc -s qdisc show dev ifb0'"
echo "停止: tc qdisc del dev $WAN_IF root; tc qdisc del dev $WAN_IF ingress; tc qdisc del dev ifb0 root; ip link del ifb0"
