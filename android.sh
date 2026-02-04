#!/data/data/com.termux/files/usr/bin/bash
# Owlia Android Bootstrap Script
# Usage: curl -sL get.owlia.bot/android | bash
#
# This script installs OpenClaw on Android via Termux.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse args
AUTO_YES=false
for arg in "$@"; do
    case $arg in
        -y|--yes) AUTO_YES=true ;;
    esac
done

print_banner() {
    echo -e "${BLUE}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║   🦉 Owlia Android Bootstrap          ║"
    echo "  ║   Powered by OpenClaw                 ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Prompt helper - reads from /dev/tty for pipe compatibility
ask() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    local prompt="$1"
    local default="${2:-Y}"
    echo -n -e "$prompt "
    read -n 1 -r REPLY < /dev/tty || REPLY=""
    echo
    if [ -z "$REPLY" ]; then
        REPLY="$default"
    fi
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if running in Termux
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "This script must be run in Termux!\n\nDownload Termux from F-Droid:\nhttps://f-droid.org/packages/com.termux/"
    fi
    success "Running in Termux"
}

# Check architecture
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        aarch64|arm64)
            success "Architecture: $ARCH (supported)"
            ;;
        armv7l|armv8l)
            warn "Architecture: $ARCH (may work, not fully tested)"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac
}

# Check available memory
check_memory() {
    MEM_MB=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$MEM_MB" -lt 1500 ]; then
        warn "Low memory: ${MEM_MB}MB. Recommended: 2GB+"
        echo -e "   OpenClaw may run slowly or crash on low-memory devices."
        if ! ask "   Continue anyway? [y/N]" "N"; then
            exit 1
        fi
    else
        success "Memory: ${MEM_MB}MB"
    fi
}

# Update packages and install dependencies
install_deps() {
    info "Updating package lists..."
    pkg update -y
    
    info "Installing dependencies..."
    pkg install -y nodejs-lts git openssl termux-api
    
    success "Dependencies installed"
}

# Install OpenClaw
install_openclaw() {
    info "Installing OpenClaw..."
    # Skip optional deps (node-llama-cpp, canvas) - not needed for cloud LLM
    npm install -g openclaw@latest --omit=optional
    
    if command -v openclaw &> /dev/null; then
        VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
        success "OpenClaw installed: $VERSION"
    else
        error "OpenClaw installation failed"
    fi
}

# Create minimal config
create_config() {
    CONFIG_DIR="$HOME/.openclaw"
    CONFIG_FILE="$CONFIG_DIR/openclaw.json"
    
    mkdir -p "$CONFIG_DIR"
    
    if [ -f "$CONFIG_FILE" ]; then
        warn "Config already exists: $CONFIG_FILE"
        if ! ask "   Overwrite? [y/N]" "N"; then
            return
        fi
    fi
    
    info "Creating config..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "$schema": "https://openclaw.ai/schema/config.json",
  "gateway": {
    "bind": "loopback",
    "port": 18789
  },
  "session": {
    "mainKey": "main"
  },
  "heartbeat": {
    "enabled": true,
    "intervalMinutes": 30
  }
}
EOF
    
    success "Config created: $CONFIG_FILE"
}

# Setup wake lock for background running
setup_wakelock() {
    info "Setting up wake lock..."
    
    mkdir -p "$HOME/.openclaw/scripts"
    cat > "$HOME/.openclaw/scripts/start-gateway.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start OpenClaw gateway with wake lock
termux-wake-lock
exec openclaw gateway --verbose
EOF
    chmod +x "$HOME/.openclaw/scripts/start-gateway.sh"
    
    success "Wake lock script created"
}

# Setup boot startup (optional)
setup_boot() {
    if ! ask "Setup auto-start on boot? [y/N]" "N"; then
        return
    fi
    
    info "Setting up boot script..."
    if [ ! -d "$HOME/.termux/boot" ]; then
        mkdir -p "$HOME/.termux/boot"
        warn "termux-boot app required for auto-start"
        echo -e "   Install from F-Droid: https://f-droid.org/packages/com.termux.boot/"
    fi
    
    cat > "$HOME/.termux/boot/start-openclaw.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sleep 10  # Wait for network
openclaw gateway &
EOF
    chmod +x "$HOME/.termux/boot/start-openclaw.sh"
    
    success "Boot script created"
}

# Battery optimization notice
show_battery_notice() {
    echo
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}   ⚡ Important: Battery Optimization   ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "To keep OpenClaw running in background:"
    echo
    echo "1. Open Android Settings"
    echo "2. Go to Apps → Termux → Battery"
    echo "3. Select 'Unrestricted' or 'Don't optimize'"
    echo
}

# Run onboarding
run_onboard() {
    echo
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}   Setup Complete! Starting Onboarding ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo
    echo "Next steps:"
    echo "  1. Set up your AI provider (API key or OAuth)"
    echo "  2. Connect a chat channel (Telegram/Discord/WhatsApp)"
    echo "  3. Start chatting!"
    echo
    
    if ! ask "Start onboarding wizard now? [Y/n]" "Y"; then
        echo
        echo "To start later, run:"
        echo "  openclaw onboard"
        echo
        echo "To start the gateway manually:"
        echo "  ~/.openclaw/scripts/start-gateway.sh"
        return
    fi
    
    openclaw onboard
}

# Main
main() {
    print_banner
    
    check_termux
    check_arch
    check_memory
    
    echo
    info "This will install OpenClaw on your Android device."
    if ! ask "Continue? [Y/n]" "Y"; then
        exit 0
    fi
    
    install_deps
    install_openclaw
    create_config
    setup_wakelock
    setup_boot
    show_battery_notice
    run_onboard
    
    echo
    echo -e "${GREEN}🦉 Owlia is ready!${NC}"
    echo
}

main "$@"
