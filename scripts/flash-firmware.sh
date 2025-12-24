
#!/bin/bash
# Flash firmware script for TP-LINK TL-WR842N V3

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "wget" "tftp" "expect")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt-get install ${missing[*]}"
        exit 1
    fi
}

# Get router IP
get_router_ip() {
    read -p "Enter router IP (default: 192.168.0.1): " router_ip
    router_ip=${router_ip:-192.168.0.1}
    echo "$router_ip"
}

# Get firmware file
get_firmware_file() {
    local firmware_file=""
    
    if [ -d "output" ]; then
        local factory_files=($(ls output/*factory.bin 2>/dev/null))
        if [ ${#factory_files[@]} -gt 0 ]; then
            log_info "Found firmware files:"
            for i in "${!factory_files[@]}"; do
                echo "  $((i+1)). ${factory_files[$i]}"
            done
            
            read -p "Select firmware file (1-${#factory_files[@]}): " choice
            if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#factory_files[@]} ]; then
                firmware_file="${factory_files[$((choice-1))]}"
            fi
        fi
    fi
    
    if [ -z "$firmware_file" ]; then
        read -p "Enter firmware file path: " firmware_file
    fi
    
    if [ ! -f "$firmware_file" ]; then
        log_error "Firmware file not found: $firmware_file"
        exit 1
    fi
    
    echo "$firmware_file"
}

# Check router model
check_router_model() {
    local router_ip="$1"
    local model=""
    
    log_info "Checking router model..."
    
    # Try to get model from web interface
    model=$(curl -s "http://$router_ip" | grep -i "tl-wr842n" | head -1 || true)
    
    if [[ "$model" =~ "TL-WR842N" ]]; then
        log_info "Detected TL-WR842N router"
        return 0
    else
        log_warn "Could not detect router model automatically"
        read -p "Is this a TL-WR842N V3 router? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "This firmware is only for TL-WR842N V3"
            exit 1
        fi
    fi
}

# Backup current firmware
backup_firmware() {
    local router_ip="$1"
    
    log_step "Backing up current firmware..."
    
    # Try to backup via SSH if available
    if ssh -o ConnectTimeout=5 root@"$router_ip" "dd if=/dev/mtd0 of=/tmp/backup.bin" 2>/dev/null; then
        scp root@"$router_ip":/tmp/backup.bin "backup_$(date +%Y%m%d_%H%M%S).bin"
        log_info "Firmware backup saved"
    else
        log_warn "Could not backup firmware via SSH"
        read -p "Continue without backup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Flash via web interface
flash_web_interface() {
    local router_ip="$1"
    local firmware_file="$2"
    
    log_step "Flashing via web interface..."
    log_info "Please manually flash the firmware:"
    log_info "1. Open web browser to http://$router_ip"
    log_info "2. Login with admin credentials"
    log_info "3. Go to System Tools → Firmware Upgrade"
    log_info "4. Select file: $firmware_file"
    log_info "5. Click Upgrade and wait for completion"
    
    read -p "Press Enter when ready to continue..."
}

# Flash via TFTP
flash_tftp() {
    local router_ip="$1"
    local firmware_file="$2"
    
    log_step "Preparing TFTP flash..."
    
    # Set up TFTP server
    log_info "Setting up TFTP server..."
    
    # Create TFTP directory
    sudo mkdir -p /tftpboot
    sudo cp "$firmware_file" /tftpboot/firmware.bin
    sudo chmod 777 /tftpboot/firmware.bin
    
    # Configure TFTP server
    cat > /tmp/tftp.conf << 'EOF'
service tftp
{
    socket_type     = dgram
    protocol        = udp
    wait            = yes
    user            = root
    server          = /usr/sbin/in.tftpd
    server_args     = -s /tftpboot
    disable         = no
}
EOF
    
    sudo cp /tmp/tftp.conf /etc/xinetd.d/tftp
    sudo systemctl restart xinetd || true
    
    log_info "TFTP server configured"
    log_info "Now put router in TFTP mode:"
    log_info "1. Power off router"
    log_info "2. Hold reset button"
    log_info "3. Power on while holding reset"
    log_info "4. Release reset after 5 seconds"
    log_info "5. Router will download firmware automatically"
    
    read -p "Press Enter when router is in TFTP mode..."
}

# Flash via SSH
flash_ssh() {
    local router_ip="$1"
    local firmware_file="$2"
    
    log_step "Attempting SSH flash..."
    
    # Check if SSH is available
    if ! ssh -o ConnectTimeout=5 root@"$router_ip" "echo test" 2>/dev/null; then
        log_warn "SSH not available on router"
        return 1
    fi
    
    log_info "SSH connection available"
    read -p "Use SSH to flash firmware? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    
    # Copy firmware to router
    log_info "Copying firmware to router..."
    scp "$firmware_file" root@"$router_ip":/tmp/firmware.bin
    
    # Flash firmware
    log_info "Flashing firmware..."
    ssh root@"$router_ip" "sysupgrade -F /tmp/firmware.bin"
    
    log_info "Flash initiated, router will reboot..."
    return 0
}

# Monitor flash progress
monitor_flash_progress() {
    local router_ip="$1"
    
    log_step "Monitoring flash progress..."
    
    log_info "Waiting for router to reboot..."
    sleep 30
    
    # Try to ping router
    local attempts=0
    local max_attempts=60
    
    while [ $attempts -lt $max_attempts ]; do
        if ping -c 1 -W 2 "$router_ip" > /dev/null 2>&1; then
            log_info "Router is responding to ping"
            break
        fi
        
        attempts=$((attempts + 1))
        echo -n "."
        sleep 5
    done
    
    if [ $attempts -eq $max_attempts ]; then
        log_error "Router not responding after flash"
        return 1
    fi
    
    # Check web interface
    sleep 10
    if curl -s "http://$router_ip" | grep -q "LuCI"; then
        log_info "✓ Web interface is accessible"
        log_info "✓ Flash successful!"
        return 0
    else
        log_warn "Web interface not responding"
        return 1
    fi
}

# Main flash function
main() {
    log_info "TP-LINK TL-WR842N V3 Firmware Flash Tool"
    log_info "=========================================="
    
    check_root
    check_dependencies
    
    local router_ip=$(get_router_ip)
    local firmware_file=$(get_firmware_file)
    
    log_info "Router IP: $router_ip"
    log_info "Firmware file: $firmware_file"
    
    check_router_model "$router_ip"
    
    # Try different flash methods
    if flash_ssh "$router_ip" "$firmware_file"; then
        monitor_flash_progress "$router_ip"
    else
        log_info "Trying TFTP method..."
        flash_tftp "$router_ip" "$firmware_file"
        
        log_info "If TFTP doesn't work, use web interface method:"
        flash_web_interface "$router_ip" "$firmware_file"
    fi
    
    log_info "Flash process completed!"
    log_info "New IP address should be: 192.168.10.1"
    log_info "Login: admin / thdn12345678"
}

# Run main function
main "$@"
