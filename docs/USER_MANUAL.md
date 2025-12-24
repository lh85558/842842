
# TP-LINK TL-WR842N V3 LEDE 打印服务器用户手册

## 产品概述

本固件将您的 TP-LINK TL-WR842N V3 路由器转变为功能完整的网络打印服务器，支持多种打印机型号和网络打印协议。

### 主要功能
- ✅ CUPS 2.4.2 中文管理界面
- ✅ HP LaserJet 系列打印机驱动
- ✅ USB 和网络打印机支持
- ✅ 远程打印服务
- ✅ VirtualHere USB 虚拟化
- ✅ 定时自动重启
- ✅ 中文 Web 管理界面

## 快速设置

### 1. 首次连接

#### 有线连接
1. 用网线连接电脑和路由器 LAN 口
2. 设置电脑 IP 为自动获取
3. 浏览器访问 `http://192.168.10.1`

#### 无线连接
1. 搜索 WiFi 网络：`THDN-dayin`
2. 输入密码：`thdn12345678`
3. 浏览器访问 `http://192.168.10.1`

### 2. 登录系统
- **用户名**：admin
- **密码**：thdn12345678

### 3. 连接打印机
1. 通过 USB 线连接打印机到路由器
2. 等待系统自动识别（约30秒）
3. 访问 CUPS 管理界面配置

## 打印服务配置

### CUPS 管理界面

#### 访问方式
- 地址：`http://192.168.10.1:631`
- 或 LuCI → 服务 → CUPS 打印服务

#### 添加打印机
1. 点击 "添加打印机"
2. 选择检测到的 USB 打印机
3. 选择正确的驱动程序
4. 设置打印机名称和描述
5. 点击 "添加打印机"

#### 常用设置
- **纸张大小**：A4（默认）
- **打印质量**：600dpi（标准）
- **颜色模式**：黑白/彩色

### HP 打印机配置

#### 支持的型号
- HP LaserJet 1020/1020 Plus
- HP LaserJet 1007/1008
- HP LaserJet 1108
- 其他兼容 foo2zjs 驱动的型号

#### 自动配置
系统会自动检测 HP 打印机并安装相应驱动。

#### 手动配置
```bash
# SSH 登录路由器
ssh root@192.168.10.1

# 查看连接的打印机
lsusb

# 手动添加打印机
lpadmin -p HP-Printer -E -v usb://HP -m drv:///foo2zjs.drv/laserjet.ppd
```

### 网络打印设置

#### IPP 协议（推荐）
- **地址**：`ipp://192.168.10.1:631/printers/打印机名`
- **端口**：631
- **协议**：IPP

#### RAW 协议
- **地址**：`socket://192.168.10.1:9100`
- **端口**：9100
- **协议**：RAW

#### SMB 共享
```bash
# 启用 SMB 共享（可选）
/etc/init.d/samba enable
/etc/init.d/samba start
```

## 客户端配置

### Windows 10/11

#### 方法 1: IPP 打印
1. 设置 → 设备 → 打印机和扫描仪
2. 点击 "添加打印机或扫描仪"
3. 点击 "我需要的打印机不在列表中"
4. 选择 "使用 TCP/IP 地址或主机名添加打印机"
5. 输入：
   - 主机名：192.168.10.1
   - 端口：631
   - 协议：IPP
6. 选择打印机驱动程序
7. 完成安装

#### 方法 2: 网络发现
1. 文件资源管理器 → 网络
2. 找到 THDN-PrintServer
3. 双击共享的打印机
4. 安装驱动程序

### macOS

#### IPP 打印
1. 系统偏好设置 → 打印机与扫描仪
2. 点击 "+" 添加打印机
3. 选择 "IP" 选项卡
4. 输入：
   - 地址：192.168.10.1
   - 协议：IPP
   - 队列：/printers/打印机名
5. 选择驱动程序
6. 点击 "添加"

### Linux (Ubuntu/Debian)

#### CUPS 客户端
```bash
# 安装 CUPS 客户端
sudo apt-get install cups-client

# 添加打印机
sudo lpadmin -p NetworkPrinter -E -v ipp://192.168.10.1:631/printers/打印机名

# 设置为默认打印机
sudo lpoptions -d NetworkPrinter
```

#### 图形界面
1. 设置 → 打印机
2. 点击 "添加"
3. 选择网络打印机
4. 输入 IP 地址：192.168.10.1
5. 完成配置

### Android/iOS

#### 移动打印
1. 安装打印应用（如 PrinterShare）
2. 添加网络打印机
3. 输入 IP：192.168.10.1
4. 选择打印机型号

## 高级功能

### VirtualHere USB 虚拟化

#### 功能说明
将 USB 打印机虚拟化为网络设备，支持远程 USB 连接。

#### 使用方法
1. 在客户端安装 VirtualHere 软件
2. 连接到 192.168.10.1:7575
3. 找到 USB 打印机
4. 右键 → 使用此设备

#### 客户端下载
- Windows: https://www.virtualhere.com/usb_client_software
- macOS: https://www.virtualhere.com/usb_client_software
- Linux: 通过包管理器安装

### 远程访问

#### 端口转发
在路由器上配置端口转发：
- 外部端口：631
- 内部 IP：192.168.10.1
- 内部端口：631

#### 安全建议
```bash
# 修改 CUPS 配置限制访问
vi /etc/cups/cupsd.conf

# 添加访问控制
<Location />
  Order allow,deny
  Allow from 192.168.10.0/24
  Allow from your.remote.ip
</Location>
```

### 定时任务

#### 自动重启
默认设置：每周二凌晨 4 点自动重启

#### 修改重启时间
```bash
# 编辑定时任务
crontab -e

# 修改重启时间（每天凌晨 3 点）
0 3 * * * /sbin/reboot
```

#### 日志轮转
```bash
# 查看日志轮转配置
cat /etc/logrotate.conf

# 手动轮转日志
logrotate -f /etc/logrotate.conf
```

## 故障排除

### 打印机问题

#### 无法识别打印机
**检查步骤：**
1. 确认 USB 连接正常
2. 检查打印机电源
3. 查看系统日志：
   ```bash
   logread | grep printer
   dmesg | grep usb
   ```

4. 重启 CUPS 服务：
   ```bash
   /etc/init.d/cups-setup restart
   ```

#### 打印质量问题
**解决方案：**
1. 检查驱动程序选择
2. 调整打印质量设置
3. 清洁打印头
4. 更换墨盒/硒鼓

#### 打印速度慢
**优化方法：**
1. 降低打印质量
2. 使用 RAW 协议
3. 检查网络连接
4. 重启打印服务

### 网络问题

#### 无法访问管理界面
**排查步骤：**
1. 检查 IP 设置（192.168.10.1）
2. 尝试 ping 路由器
3. 检查网线连接
4. 重启网络服务：
   ```bash
   /etc/init.d/network restart
   ```

#### WiFi 连接问题
**解决方案：**
1. 检查 WiFi 开关
2. 重新设置 WiFi 配置
3. 更改信道（1, 6, 11）
4. 调整发射功率

### 系统问题

#### 系统运行缓慢
**优化方法：**
1. 检查内存使用：
   ```bash
   free -m
   top
   ```

2. 清理日志文件：
   ```bash
   rm -f /var/log/*.log
   ```

3. 重启服务：
   ```bash
   /etc/init.d/cups-setup restart
   ```

#### 存储空间不足
**清理方法：**
1. 删除旧的软件包：
   ```bash
   opkg clean
   ```

2. 清理临时文件：
   ```bash
   rm -rf /tmp/*
   ```

3. 检查大文件：
   ```bash
   du -sh /* | sort -hr | head -20
   ```

## 性能优化

### 内存优化
```bash
# 禁用不必要的服务
/etc/init.d/dnsmasq disable
/etc/init.d/firewall disable

# 优化内存使用
echo 1 > /proc/sys/vm/drop_caches
```

### 网络优化
```bash
# 优化 TCP 设置
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
sysctl -p
```

### 打印优化
```bash
# 优化 CUPS 配置
vi /etc/cups/cupsd.conf

# 添加优化设置
MaxJobs 100
MaxPrinterHistory 100
AutoPurgeJobs Yes
```

## 安全设置

### 密码安全
```bash
# 修改管理员密码
passwd admin

# 修改 root 密码
passwd
```

### 防火墙配置
```bash
# 查看防火墙状态
/etc/init.d/firewall status

# 添加自定义规则
vi /etc/config/firewall

# 重启防火墙
/etc/init.d/firewall restart
```

### 访问控制
```bash
# 限制 CUPS 访问
vi /etc/cups/cupsd.conf

# 只允许内网访问
<Location />
  Order allow,deny
  Allow from 192.168.10.0/24
</Location>
```

## 备份与恢复

### 配置备份
```bash
# 备份配置文件
tar -czf /tmp/config-backup.tar.gz /etc/config/

# 下载备份文件
scp root@192.168.10.1:/tmp/config-backup.tar.gz .
```

### 系统恢复
```bash
# 恢复配置文件
tar -xzf config-backup.tar.gz -C /

# 重启相关服务
/etc/init.d/network restart
/etc/init.d/cups-setup restart
```

## 系统信息

### 查看系统状态