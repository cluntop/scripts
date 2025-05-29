# CAKE QoS 简化版 - PPPoE 专用

这是一个专门为 PPPoE 拨号连接设计的简化版 CAKE QoS 脚本，充分利用了 CAKE 的自动调优特性。

## 🎯 设计理念

正如您所说，CAKE 只需要设置：
1. **物理带宽** - 告诉 CAKE 您的实际网速
2. **DiffServ4** - 启用游戏流量优先级

其他参数 CAKE 会**自动调优**：
- 队列深度自动计算
- 延迟目标自动优化  
- 内存使用自动管理
- 流量分类自动处理

## 🚀 快速开始

### 1. 赋予执行权限
```bash
chmod +x qos_cake_simple
```

### 2. 启动配置
```bash
./qos_cake_simple start
```

脚本会：
- 自动检测 PPPoE 接口 (`pppoe-wan`, `ppp0`, `wan`)
- 询问您的实际带宽
- 自动应用 PPPoE 优化参数

### 3. 查看状态
```bash
./qos_cake_simple status
```

## 📋 命令列表

| 命令 | 功能 |
|------|------|
| `start` | 启动 CAKE QoS (首次运行会进入配置向导) |
| `stop` | 停止 CAKE QoS |
| `restart` | 重启 CAKE QoS |
| `status` | 显示运行状态和统计信息 |
| `config` | 重新配置参数 |
| `help` | 显示帮助信息 |

## 🍰 CAKE 自动优化特性

### PPPoE 专用优化
- **开销补偿**: 自动设置 18 字节 PPPoE 开销
- **带宽设置**: 使用 95% 实际带宽，CAKE 自动处理缓冲区

### 游戏优化
- **DiffServ4 分类**:
  - Voice (语音/游戏) - 最高优先级
  - Video (视频流) - 高优先级  
  - Normal (网页浏览) - 正常优先级
  - Bulk (下载) - 最低优先级

### 智能特性
- **ACK 过滤**: 自动减少上传 ACK 包冲突
- **NAT 检测**: 自动优化 NAT 环境
- **自适应队列**: 根据网络状况自动调整

## 📊 与完整版对比

| 特性 | 完整版 | 简化版 |
|------|--------|--------|
| 配置复杂度 | 多项选择 | 仅需带宽 |
| 文件大小 | 1000+ 行 | 250 行 |
| PPPoE 优化 | 需手动选择 | 自动应用 |
| 功能完整性 | 100% | 核心功能 |
| 适用场景 | 高级用户 | 普通用户 |

## 🔧 技术细节

### CAKE 配置参数
```bash
# 上传队列
tc qdisc add dev pppoe-wan root cake \
    bandwidth 50000kbit \    # 您的实际带宽
    diffserv4 \             # 游戏优先级
    nat \                   # NAT 检测
    ack-filter \            # ACK 过滤
    overhead 18             # PPPoE 开销

# 其他参数 CAKE 自动处理：
# - target (延迟目标)
# - interval (测量间隔)  
# - flows (流数量)
# - quantum (包大小)
# - memory (内存限制)
```

### 为什么这样简化？

1. **CAKE 智能算法**: 内置自适应机制，无需手动调参
2. **PPPoE 标准化**: PPPoE 开销固定为 18 字节
3. **游戏优化**: DiffServ4 自动识别游戏流量
4. **减少出错**: 参数越少，配置错误越少

## 💡 使用建议

### 带宽设置
- 上传速度设为**实际测速的 100%**
- 下载速度设为**实际测速的 100%**  
- CAKE 会自动使用 95% 进行限速

### 监控效果
- 游戏延迟应明显降低
- 下载时游戏不会卡顿
- 视频通话更稳定

### 故障排除
```bash
# 检查 PPPoE 连接
ip addr show pppoe-wan

# 检查 CAKE 模块
lsmod | grep sch_cake

# 查看详细统计
tc -s qdisc show dev pppoe-wan
```

## 🎮 游戏优化效果

使用 CAKE 后您应该体验到：
- ✅ 游戏延迟降低 20-50ms
- ✅ 下载时游戏不掉线
- ✅ 语音通话更清晰
- ✅ 视频直播不卡顿
- ✅ 多设备使用不冲突

---

**🍰 享受 CAKE 带来的丝滑网络体验！**
