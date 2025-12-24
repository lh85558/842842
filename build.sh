
#!/bin/bash
# TP-LINK 842N V3 LEDE Print Server Build Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running on Ubuntu 22.04
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    log_warn "This script is optimized for Ubuntu 22.04"
fi

# Install dependencies
log_info "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
    python3-distutils python3-setuptools python3-dev rsync subversion \
    swig time xsltproc zlib1g-dev

# Create build directory
BUILD_DIR="openwrt-build"
if [ -d "$BUILD_DIR" ]; then
    log_warn "Build directory exists, removing..."
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone OpenWrt 21.02
log_info "Cloning OpenWrt 21.02..."
git clone --depth 1 --branch openwrt-21.02 https://github.com/openwrt/openwrt.git
cd openwrt

# Add immortalwrt feeds for additional packages
log_info "Adding immortalwrt feeds..."
echo "src-git immortalwrt https://github.com/immortalwrt/packages.git;openwrt-21.02" >> feeds.conf.default
echo "src-git immortalwrt_luci https://github.com/immortalwrt/luci.git;openwrt-21.02" >> feeds.conf.default

# Update and install feeds
log_info "Updating feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# Copy configuration and files
log_info "Copying configuration..."
cp ../../config/842n-v3.config .config
cp -r ../../files/ ./

# Configure build
log_info "Configuring build..."
make defconfig

# Download sources
log_info "Downloading sources..."
make download -j$(nproc)

# Build firmware
log_info "Building firmware (this may take a while)..."
make -j$(nproc) V=s

# Copy output files
log_info "Copying output files..."
mkdir -p ../../output
cp bin/targets/ath79/generic/*842n-v3*sysupgrade.bin ../../output/ 2>/dev/null || true
cp bin/targets/ath79/generic/*842n-v3*factory.bin ../../output/ 2>/dev/null || true
cp bin/targets/ath79/generic/*842n-v3*factory-us.bin ../../output/ 2>/dev/null || true

# Create build info
cat > ../../output/build-info.txt << EOF
TP-LINK TL-WR842N V3 LEDE Print Server Build Information
========================================================
Build Date: $(date)
OpenWrt Version: 21.02
Target: ath79/generic
Device: TP-LINK TL-WR842N V3

Features:
- CUPS 2.4.2 with Chinese interface
- HP LaserJet 1020/1020plus/1007/1008/1108 drivers
- USB printer support
- Network printer sharing
- Remote printing (port 631)
- VirtualHere USB virtualization
- Scheduled weekly restart (Tue 04:00)
- Chinese LuCI interface

Default Settings:
- LAN IP: 192.168.10.1
- Web Login: admin / thdn12345678
- WiFi: THDN-dayin / thdn12345678
- Hostname: THDN-PrintServer

Files:
- sysupgrade.bin: Upgrade from existing OpenWrt
- factory.bin: Fresh installation
EOF

log_info "Build completed! Check the output directory for firmware files."
log_info "Output directory: $(pwd)/../../output"
