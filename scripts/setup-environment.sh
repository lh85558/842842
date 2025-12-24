
#!/bin/bash
# Environment setup script for Ubuntu 22.04

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        log_warn "This script is optimized for Ubuntu 22.04"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Configure APT sources for China
configure_apt_sources() {
    log_info "Configuring APT sources for China..."
    
    # Backup original sources
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    
    # Use Tsinghua mirror
    cat > /tmp/sources.list << 'EOF'
# Ubuntu 22.04 Tsinghua Mirror
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse

# Source packages
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF
    
    sudo mv /tmp/sources.list /etc/apt/sources.list
    sudo apt-get update
}

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."
    
    sudo apt-get install -y \
        build-essential \
        ccache \
        ecj \
        fastjar \
        file \
        g++ \
        gawk \
        gettext \
        git \
        java-propose-classpath \
        libelf-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libssl-dev \
        python3 \
        python3-distutils \
        python3-setuptools \
        python3-dev \
        python2.7-dev \
        unzip \
        wget \
        rsync \
        subversion \
        swig \
        time \
        xsltproc \
        zlib1g-dev \
        bc \
        curl \
        jq \
        vim \
        nano \
        htop \
        tree
}

# Configure Git
configure_git() {
    log_info "Configuring Git..."
    
    if ! git config --global user.name > /dev/null; then
        read -p "Enter Git user name: " git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email > /dev/null; then
        read -p "Enter Git user email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Configure Git for China
    git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"
    git config --global url."https://hub.fastgit.org/".insteadOf "https://github.com/"
}

# Configure environment variables
configure_environment() {
    log_info "Configuring environment variables..."
    
    cat >> ~/.bashrc << 'EOF'

# OpenWrt Build Environment
export FORCE_UNSAFE_CONFIGURE=1
export MAKE_JOBSERVER=$(nproc)
export CCACHE_DIR=$HOME/.ccache
export PATH=$PATH:$HOME/openwrt/staging_dir/host/bin

# Aliases for build
alias owrt='cd ~/openwrt'
alias owrt-menu='make menuconfig'
alias owrt-clean='make clean'
alias owrt-dirclean='make dirclean'
alias owrt-distclean='make distclean'
EOF
    
    # Create ccache directory
    mkdir -p ~/.ccache
}

# Configure ccache
configure_ccache() {
    log_info "Configuring ccache..."
    
    ccache --max-size=10G
    ccache --set-config=compression=true
    ccache --set-config=compression_level=6
}

# Main setup function
main() {
    log_info "Starting environment setup for TP-LINK 842N V3 LEDE build..."
    
    check_ubuntu
    configure_apt_sources
    install_dependencies
    configure_git
    configure_environment
    configure_ccache
    
    log_info "Environment setup completed!"
    log_info "Please restart your terminal or run: source ~/.bashrc"
    log_info "Then you can use 'make' command to build the firmware"
}

# Run main function
main "$@"
