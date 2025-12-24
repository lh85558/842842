
# TP-LINK TL-WR842N V3 LEDE 中文打印服务器固件

基于 OpenWrt 21.02 的定制固件，专为 TP-LINK TL-WR842N V3 路由器打造，集成完整的打印服务器功能。

## 功能特性

### 🖨️ 打印服务
- **CUPS 2.4.2** - 中文 Web 管理界面
- **HP 驱动支持** - LaserJet 1020/1020plus/1007/1008/1108
- **USB 打印机** - 即插即用支持
- **网络打印** - IPP 协议支持
- **远程打印** - 端口 631 防火墙放行
- **p910nd** - 9100 端口打印服务

### 🔧 系统功能
- **VirtualHere** - USB 设备虚拟化
- **定时重启** - 每周二凌晨 4 点自动重启
- **中文界面** - LuCI 管理界面完全中文化
- **网络优化** - 国内镜像源加速

### 📡 网络配置
- **LAN IP**: 192.168.10.1
- **Web 登录**: admin / thdn12345678
- **WiFi SSID**: THDN-dayin
- **WiFi 密码**: thdn12345678
- **主机名**: THDN-PrintServer

## 快速开始

### 方法一：GitHub Actions 自动编译
1. Fork 本项目
2. 进入 Actions 页面
3. 手动触发工作流或等待自动编译
4. 在 Releases 页面下载固件

### 方法二：本地编译
```bash
# 克隆项目
git clone https://github.com/your-repo/tplink-842n-v3-lede-printserver.git
cd tplink-842n-v3-lede-printserver

# 运行编译脚本
chmod +x build.sh
./build.sh
```

## 固件说明

### 文件类型
- **sysupgrade.bin** - 从现有 OpenWrt 升级
- **factory.bin** - 原厂固件刷机

### 刷机步骤
1. 进入路由器管理界面 (192.168.0.1)
2. 选择固件升级
3. 上传 factory.bin 文件
4. 等待重启完成

## 使用指南

### 访问管理界面
- 浏览器访问: http://192.168.10.1
- 用户名: admin
- 密码: thdn12345678

### 配置打印机
1. 连接 USB 打印机
2. 访问 CUPS 管理界面: http://192.168.10.1:631
3. 点击 "添加打印机"
4. 选择检测到的打印机
5. 安装对应驱动程序

### 远程打印
- Windows: 添加网络打印机 → http://192.168.10.1:631/printers/打印机名
- macOS: 系统偏好设置 → 打印机与扫描仪 → 添加 IP 打印机
- Linux: 使用 CUPS 管理界面或 IPP 协议

## 技术规格

### 硬件要求
- **设备**: TP-LINK TL-WR842N V3
- **闪存**: 16MB
- **内存**: 64MB
- **USB**: 1×USB 2.0

### 软件环境
- **基础系统**: OpenWrt 21.02.7
- **内核版本**: Linux 5.4.x
- **Web 服务器**: uhttpd
- **打印系统**: CUPS 2.4.2

## 高级配置

### 修改定时重启
编辑 `/etc/crontabs/root` 文件，修改重启时间：
```bash
# 每天凌晨 3 点重启
0 3 * * * /sbin/reboot
```

### 添加更多打印机驱动
```bash
opkg update
opkg install cups-driver-gutenprint
```

### VirtualHere 配置
```bash
# 启动 VirtualHere 服务
