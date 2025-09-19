#!/bin/bash

# Docker Setup Script for Todo Manager
# This script installs and configures Docker on Ubuntu 22.04 LTS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

update_system() {
    log_info "Updating system packages..."
    apt-get update
    apt-get upgrade -y
    log_success "System updated"
}

install_prerequisites() {
    log_info "Installing prerequisites..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        unzip \
        wget \
        git \
        htop \
        jq \
        ufw
    log_success "Prerequisites installed"
}

install_docker() {
    log_info "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    apt-get update
    
    # Install Docker Engine
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log_success "Docker installed"
}

configure_docker() {
    log_info "Configuring Docker..."
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    # Create Docker daemon configuration
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker
    
    log_success "Docker configured"
}

install_docker_compose() {
    log_info "Installing Docker Compose..."
    
    # Docker Compose is now included in docker-compose-plugin
    # Create a symlink for backward compatibility
    ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    # Verify installation
    docker-compose --version
    
    log_success "Docker Compose installed"
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Docker ports (optional)
    ufw allow 5000/tcp comment "Backend API"
    
    # Show status
    ufw status
    
    log_success "Firewall configured"
}

setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    # Create Docker log rotation
    cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
    postrotate
        /bin/kill -SIGUSR1 $(cat /var/run/docker.pid 2> /dev/null) 2> /dev/null || true
    endscript
}
EOF
    
    log_success "Log rotation configured"
}

create_docker_networks() {
    log_info "Creating Docker networks..."
    
    # Create a custom network for the application
    docker network create todo-network 2>/dev/null || true
    
    log_success "Docker networks created"
}

test_installation() {
    log_info "Testing Docker installation..."
    
    # Test Docker
    docker --version
    docker-compose --version
    
    # Run hello-world container
    docker run --rm hello-world
    
    log_success "Docker installation test passed"
}

create_management_scripts() {
    log_info "Creating management scripts..."
    
    # Create Docker management script
    cat > /usr/local/bin/docker-manage << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "Starting Docker services..."
        systemctl start docker
        ;;
    stop)
        echo "Stopping Docker services..."
        systemctl stop docker
        ;;
    restart)
        echo "Restarting Docker services..."
        systemctl restart docker
        ;;
    status)
        echo "Docker status:"
        systemctl status docker
        echo
        echo "Running containers:"
        docker ps
        ;;
    logs)
        shift
        docker logs "$@"
        ;;
    clean)
        echo "Cleaning up Docker resources..."
        docker system prune -f
        docker volume prune -f
        ;;
    *)
        echo "Usage: docker-manage {start|stop|restart|status|logs|clean}"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/docker-manage
    
    log_success "Management scripts created"
}

show_completion_info() {
    log_info "Docker setup completed!"
    echo
    echo "=========================================="
    echo "Docker Installation Summary"
    echo "=========================================="
    echo "Docker Version: $(docker --version)"
    echo "Docker Compose Version: $(docker-compose --version)"
    echo
    echo "Useful Commands:"
    echo "  Check status: docker-manage status"
    echo "  View logs: docker-manage logs <container>"
    echo "  Clean up: docker-manage clean"
    echo "  Restart Docker: docker-manage restart"
    echo
    echo "Next Steps:"
    echo "  1. Logout and login again to apply group changes"
    echo "  2. Run the deployment script to deploy the application"
    echo "=========================================="
}

# Main execution
main() {
    echo "=========================================="
    echo "Docker Setup Script for Todo Manager"
    echo "=========================================="
    echo
    
    check_root
    update_system
    install_prerequisites
    install_docker
    configure_docker
    install_docker_compose
    configure_firewall
    setup_log_rotation
    create_docker_networks
    test_installation
    create_management_scripts
    show_completion_info
    
    log_success "Docker setup completed successfully!"
}

# Run main function
main "$@"
