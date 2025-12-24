
# TP-LINK TL-WR842N V3 LEDE 打印服务器构建指南

## 系统要求

### 硬件要求
- 64位处理器（推荐多核）
- 至少 4GB RAM（推荐 8GB+）
- 至少 20GB 可用磁盘空间
- 稳定的网络连接

### 操作系统
- Ubuntu 22.04 LTS（推荐）
- 其他基于 Debian 的发行版（需要修改）

## 快速开始

### 1. 环境准备

```bash
# 运行环境配置脚本
chmod +x scripts/setup-environment.sh
sudo ./scripts/setup-environment.sh

# 重新加载环境变量
source ~/.bashrc
```

### 2. 一键构建

```bash
# 使用 Makefile 构建
make all

# 或者使用构建脚本
chmod +x build.sh
./build.sh
```

### 3. 获取固件

构建完成后，固件文件将在 `output/` 目录中：
- `*sysupgrade.bin` - 用于 OpenWrt 升级
- `*factory.bin` - 用于原厂固件刷机

## 详细构建步骤

### 步骤 1: 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python3 python3-distutils \
    python3-setuptools python3-dev unzip wget rsync subversion \
    swig time xsltproc zlib1g-dev bc curl
```

### 步骤 2: 克隆源码

```bash
# 创建工作目录
mkdir -p ~/openwrt-build
cd ~/openwrt-build

# 克隆 OpenWrt 21.02
git clone --depth 1 --branch openwrt-21.02 https://github.com/openwrt/openwrt.git
cd openwrt
```

### 步骤 3: 配置 feeds

```bash
# 添加国内镜像源
echo "src-git immortalwrt https://github.com/immortalwrt/packages.git;openwrt-21.02" >> feeds.conf.default
echo "src-git immortalwrt_luci https://github.com/immortalwrt/luci.git;openwrt-21.02" >> feeds.conf.default

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a
```

### 步骤 4: 应用配置

```bash
# 复制配置文件
cp /path/to/your/842n-v3.config .config

# 或者使用 menuconfig 手动配置
make menuconfig

# 应用配置
make defconfig
```

### 步骤 5: 下载源码

```bash
# 下载所有源码包（耗时较长）
make download -j$(nproc)

# 检查下载完整性
make download -j$(nproc) V=s | grep -i error
```

### 步骤 6: 开始构建

```bash
# 开始编译（耗时较长，1-3小时）
make -j$(nproc) V=s

# 或者单线程编译（更稳定）
make V=s
```

## 配置说明

### 关键配置选项

```bash
# Target System
CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_tplink_tl-wr842n-v3=y

# USB Support
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb-printer=y
CONFIG_PACKAGE_kmod-usb-storage=y

# CUPS
CONFIG_PACKAGE_cups=y
CONFIG_PACKAGE_cups-filters=y
CONFIG_PACKAGE_cups-driver-foo2zjs=y

# Chinese Support
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
```

### 网络配置

```bash
# LAN IP
CONFIG_PACKAGE_luci-mod-admin-full=y
# 默认 IP: 192.168.10.1

# WiFi
CONFIG_PACKAGE_hostapd=y
# SSID: THDN-dayin
# 密码: thdn12345678
```

## 构建优化

### 使用 ccache 加速

```bash
# 安装 ccache
sudo apt-get install ccache

# 配置 ccache
ccache --max-size=10G
export CCACHE_DIR=$HOME/.ccache
```

### 使用多线程

```bash
# 自动检测 CPU 核心数
make -j$(nproc)

# 指定线程数
make -j8 V=s
```

### 断点续编

```bash
# 如果构建中断，重新运行相同的 make 命令
make -j$(nproc) V=s
```

## 故障排除

### 常见问题

#### 1. 构建失败：内存不足
```bash
# 增加 swap 空间
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 2. 下载失败
```bash
# 使用代理
export http_proxy=http://proxy.server:port
export https_proxy=http://proxy.server:port

# 或者手动下载
wget -c https://downloads.openwrt.org/...
```

#### 3. 配置错误
```bash
# 清理配置
make clean
rm -rf tmp/

# 重新配置
make menuconfig
```

#### 4. 依赖缺失
```bash
# 检查缺失的依赖
make V=s 2>&1 | grep -i error

# 安装缺失的包
sudo apt-get install <missing-package>
```

### 清理构建

```bash
# 清理编译结果
make clean

# 清理所有生成的文件
make dirclean

# 完全清理（包括配置）
make distclean
```

## 高级用法

### 自定义包

```bash
# 创建自定义包目录
mkdir -p package/custom

# 添加自定义包
cp -r /path/to/custom/package package/custom/

# 重新配置
make menuconfig
```

### 修改内核配置

```bash
# 进入内核配置
make kernel_menuconfig

# 保存并退出
# 重新构建
make -j$(nproc) V=s
```

### 添加自定义文件

```bash
# 创建 files 目录
mkdir -p files/

# 添加自定义文件
cp -r /path/to/custom/files/* files/

# 重新构建
make -j$(nproc) V=s
```

## 输出文件

构建完成后，检查输出目录：

```bash
ls -la bin/targets/ath79/generic/

# 主要文件：
# openwrt-ath79-generic-tplink_tl-wr842n-v3-squashfs-factory.bin
# openwrt-ath79-generic-tplink_tl-wr842n-v3-squashfs-sysupgrade.bin
```

## 验证固件

### 检查文件大小
```bash
ls -lh bin/targets/ath79/generic/*842n-v3*.bin
```

### 验证 MD5
```bash
md5sum bin/targets/ath79/generic/*842n-v3*.bin
```

### 文件信息
```bash
file bin/targets/ath79/generic/*842n-v3*.bin
```

## 下一步

构建完成后，参考 [FLASH_GUIDE.md](FLASH_GUIDE.md) 了解如何刷入固件。
