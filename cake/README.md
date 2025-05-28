# CAKE QoS 游戏优化脚本

这是基于 CAKE (Common Applications Kept Enhanced) 算法的 QoS 流量控制脚本，专门为游戏网络优化设计。

## 🍰 CAKE vs fq_codel 主要优势

### CAKE 特有功能
- **智能流量分类**: 自动识别游戏、语音、视频、下载等不同类型流量
- **DiffServ4 支持**: Voice > Video > Normal > Bulk 四级优先级
- **智能 ACK 过滤**: 自动处理上传队列中的 ACK 包冲突
- **NAT 感知**: 在 NAT 环境下自动优化流量管理
- **更精确的延迟控制**: 比 fq_codel 更低的延迟和更稳定的游戏体验

### 性能对比
| 特性 | fq_codel | CAKE |
|------|----------|------|
| 流量分类 | 基于哈希 | 智能DiffServ |
| ACK处理 | 普通队列 | 智能过滤 |
| NAT优化 | 无 | 自动检测 |
| 延迟控制 | 好 | 更好 |
| CPU占用 | 低 | 中等 |

## 🚀 快速开始

### 1. 检查内核支持
```bash
# 检查 CAKE 内核模块
lsmod | grep sch_cake

# 如果没有显示，尝试加载模块
modprobe sch_cake

# 再次检查是否加载成功
lsmod | grep sch_cake

# 如果仍然失败，需要安装支持 CAKE 的内核
```

### 2. 基本使用
```bash
# 赋予执行权限
chmod +x qos_cake

# 启动向导配置
./qos_cake start

# 实时监控 CAKE 队列
./qos_cake monitor

# 停止 QoS
./qos_cake stop
```

## 📊 监控界面说明

### CAKE 队列状态
- **🍰 CAKE主动流控**: 表示 CAKE 正在智能管理流量
- **🏷️ 流分类统计**: 显示不同优先级流量的数量
- **⚡ ACK过滤**: 显示 ACK 包优化效果
- **内存使用**: CAKE 队列的内存占用情况

### 游戏性能指标
- **语音流量**: 最高优先级，用于游戏语音
- **视频流量**: 高优先级，用于直播等
- **普通流量**: 正常优先级，游戏数据包
- **批量流量**: 低优先级，下载更新等

## ⚙️ 配置选项

### 连接类型
- **PPPoE**: 开销 18 bytes（最常见）
- **以太网**: 开销 14 bytes
- **自定义**: 根据实际网络环境设置

### CAKE 特性
- **DiffServ4**: 启用四级流量优先级（推荐）
- **NAT 检测**: 自动优化 NAT 环境（推荐）
- **ACK 过滤**: 减少上传 ACK 包冲突（推荐）

## 🎮 游戏优化特性

### 1. 智能流量识别
CAKE 可以自动识别不同类型的网络流量：
- 游戏包（通常 < 100 bytes）→ Voice 优先级
- 语音通话 → Voice 优先级  
- 视频流 → Video 优先级
- 网页浏览 → Normal 优先级
- 大文件下载 → Bulk 优先级

### 2. ACK 过滤优化
- 智能合并冗余的 ACK 包
- 减少上传队列拥塞
- 提升游戏包发送效率

### 3. NAT 环境优化
- 自动检测 NAT 连接
- 优化多设备环境下的流量分配
- 防止单一设备占用全部带宽

## 📈 性能调优建议

### 1. 带宽设置
- **上传**: 设置为实际速度的 95%（CAKE 更保守）
- **下载**: 设置为实际速度的 98%（CAKE 管理更精确）

### 2. 延迟优化
- 脚本默认设置 RTT 为 25ms
- 如果网络延迟较高，可以手动调整

### 3. 内存使用
- CAKE 会自动管理队列内存
- 监控界面显示当前内存使用情况

## 🔧 故障排除

### 1. CAKE 不支持
```bash
# 检查内核模块
lsmod | grep sch_cake

# 手动加载模块
modprobe sch_cake
```

### 2. 配置不生效
```bash
# 检查接口状态
ip link show

# 查看当前队列配置
tc qdisc show dev eth1

# 重新配置
./qos_cake reconfig
```

### 3. 性能异常
```bash
# 重置统计数据
./qos_cake reset

# 重启 QoS
./qos_cake restart

# 查看详细配置
./qos_cake config
```

## 📁 文件说明

- `qos_cake`: CAKE 版本的 QoS 脚本
- `qos`: 原始的 fq_codel 版本脚本
- `/etc/config/qos_cake`: CAKE 配置文件
- `/etc/sysctl.d/99-cake-qos-optimizations.conf`: CAKE 优化的内核参数

## 🆚 选择建议

### 使用 CAKE 的情况
- 需要更精细的流量控制
- 多设备游戏环境
- 对延迟要求极高
- 网络环境复杂（多种应用混合）

### 使用 fq_codel 的情况
- 追求最低 CPU 占用
- 简单的网络环境
- 内核不支持 CAKE
- 已经满意现有性能

## 🔗 相关链接

- [CAKE 官方文档](https://www.bufferbloat.net/projects/codel/wiki/Cake/)
- [Bufferbloat 项目](https://www.bufferbloat.net/)
- [OpenWrt QoS 指南](https://openwrt.org/docs/guide-user/network/traffic-shaping/start)

## 📝 更新日志

### v1.0 (2024-12-19)
- 首个 CAKE 版本
- 支持 DiffServ4 流量分类
- 智能 ACK 过滤
- NAT 环境优化
- 实时监控界面
- 游戏性能优化

---

🎮 祝您游戏愉快，网络畅通！
