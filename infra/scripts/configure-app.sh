#!/bin/bash

# Application Configuration Script for Todo Manager
# This script configures the application environment and settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="todo-manager"
APP_DIR="/opt/${PROJECT_NAME}"
ENV_FILE="${APP_DIR}/.env"
ENV_EXAMPLE="${APP_DIR}/infra/docker/env.example"

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

check_requirements() {
    log_info "Checking requirements..."
    
    if [ ! -d "$APP_DIR" ]; then
        log_error "Application directory not found: $APP_DIR"
        exit 1
    fi
    
    if [ ! -f "$ENV_EXAMPLE" ]; then
        log_error "Environment example file not found: $ENV_EXAMPLE"
        exit 1
    fi
    
    log_success "Requirements check passed"
}

create_env_file() {
    log_info "Creating environment configuration file..."
    
    if [ -f "$ENV_FILE" ]; then
        log_warning "Environment file already exists: $ENV_FILE"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing environment file"
            return 0
        fi
    fi
    
    # Copy example file
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log_success "Environment file created: $ENV_FILE"
}

configure_database() {
    log_info "Configuring database settings..."
    
    read -p "Enter database password (default: todo123): " db_password
    db_password=${db_password:-todo123}
    
    # Update database configuration
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_password/" "$ENV_FILE"
    
    log_success "Database configuration updated"
}

configure_github() {
    log_info "Configuring GitHub integration..."
    
    read -p "Enter GitHub owner/username: " github_owner
    read -p "Enter GitHub repository name: " github_repo
    read -p "Enter GitHub personal access token: " github_token
    read -p "Enter GitHub webhook secret (optional): " github_webhook_secret
    
    # Update GitHub configuration
    sed -i "s/GITHUB_OWNER=.*/GITHUB_OWNER=$github_owner/" "$ENV_FILE"
    sed -i "s/GITHUB_REPO=.*/GITHUB_REPO=$github_repo/" "$ENV_FILE"
    sed -i "s/GITHUB_TOKEN=.*/GITHUB_TOKEN=$github_token/" "$ENV_FILE"
    sed -i "s/GITHUB_WEBHOOK_SECRET=.*/GITHUB_WEBHOOK_SECRET=$github_webhook_secret/" "$ENV_FILE"
    
    log_success "GitHub configuration updated"
}

configure_email() {
    log_info "Configuring email settings..."
    
    read -p "Enter SMTP host (default: smtp.gmail.com): " smtp_host
    smtp_host=${smtp_host:-smtp.gmail.com}
    
    read -p "Enter SMTP port (default: 587): " smtp_port
    smtp_port=${smtp_port:-587}
    
    read -p "Enter SMTP username: " smtp_user
    read -p "Enter SMTP password: " smtp_pass
    read -p "Enter alert from email: " alert_from
    read -p "Enter alert to email: " alert_to
    
    # Update email configuration
    sed -i "s/SMTP_HOST=.*/SMTP_HOST=$smtp_host/" "$ENV_FILE"
    sed -i "s/SMTP_PORT=.*/SMTP_PORT=$smtp_port/" "$ENV_FILE"
    sed -i "s/SMTP_USER=.*/SMTP_USER=$smtp_user/" "$ENV_FILE"
    sed -i "s/SMTP_PASS=.*/SMTP_PASS=$smtp_pass/" "$ENV_FILE"
    sed -i "s/ALERT_FROM=.*/ALERT_FROM=$alert_from/" "$ENV_FILE"
    sed -i "s/ALERT_TO=.*/ALERT_TO=$alert_to/" "$ENV_FILE"
    
    log_success "Email configuration updated"
}

configure_application() {
    log_info "Configuring application settings..."
    
    # Get public IP for frontend origin
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    read -p "Enter frontend origin URL (default: http://$public_ip): " frontend_origin
    frontend_origin=${frontend_origin:-http://$public_ip}
    
    read -p "Enable GitHub polling? (Y/n): " poll_enabled
    poll_enabled=${poll_enabled:-Y}
    
    if [[ $poll_enabled =~ ^[Yy]$ ]]; then
        poll_enabled="true"
    else
        poll_enabled="false"
    fi
    
    read -p "Enter polling interval in milliseconds (default: 60000): " poll_interval
    poll_interval=${poll_interval:-60000}
    
    read -p "Enter lookback days for metrics (default: 30): " lookback_days
    lookback_days=${lookback_days:-30}
    
    # Update application configuration
    sed -i "s|FRONTEND_ORIGIN=.*|FRONTEND_ORIGIN=$frontend_origin|" "$ENV_FILE"
    sed -i "s/POLL_ENABLED=.*/POLL_ENABLED=$poll_enabled/" "$ENV_FILE"
    sed -i "s/POLL_INTERVAL_MS=.*/POLL_INTERVAL_MS=$poll_interval/" "$ENV_FILE"
    sed -i "s/LOOKBACK_DAYS=.*/LOOKBACK_DAYS=$lookback_days/" "$ENV_FILE"
    
    log_success "Application configuration updated"
}

configure_docker_images() {
    log_info "Configuring Docker images..."
    
    read -p "Enter backend image name (default: todo-manager-backend:latest): " backend_image
    backend_image=${backend_image:-todo-manager-backend:latest}
    
    read -p "Enter frontend image name (default: todo-manager-frontend:latest): " frontend_image
    frontend_image=${frontend_image:-todo-manager-frontend:latest}
    
    # Update Docker image configuration
    sed -i "s/BACKEND_IMAGE=.*/BACKEND_IMAGE=$backend_image/" "$ENV_FILE"
    sed -i "s/FRONTEND_IMAGE=.*/FRONTEND_IMAGE=$frontend_image/" "$ENV_FILE"
    
    log_success "Docker image configuration updated"
}

validate_configuration() {
    log_info "Validating configuration..."
    
    # Source the .env file
    set -a
    source "$ENV_FILE"
    set +a
    
    local errors=0
    
    # Check required variables
    local required_vars=(
        "DB_PASSWORD"
        "GITHUB_OWNER"
        "GITHUB_REPO"
        "GITHUB_TOKEN"
        "SMTP_HOST"
        "SMTP_USER"
        "SMTP_PASS"
        "ALERT_FROM"
        "ALERT_TO"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [ "${!var}" = "your-"* ]; then
            log_error "Missing or invalid configuration: $var"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Configuration validation passed"
        return 0
    else
        log_error "Configuration validation failed with $errors errors"
        return 1
    fi
}

show_configuration() {
    log_info "Current configuration:"
    echo
    echo "=========================================="
    echo "Database Configuration"
    echo "=========================================="
    echo "Host: $DB_HOST"
    echo "User: $DB_USER"
    echo "Database: $DB_NAME"
    echo "Port: $DB_PORT"
    echo "Password: [HIDDEN]"
    echo
    
    echo "=========================================="
    echo "GitHub Configuration"
    echo "=========================================="
    echo "Owner: $GITHUB_OWNER"
    echo "Repository: $GITHUB_REPO"
    echo "Token: [HIDDEN]"
    echo "Webhook Secret: [HIDDEN]"
    echo
    
    echo "=========================================="
    echo "Email Configuration"
    echo "=========================================="
    echo "SMTP Host: $SMTP_HOST"
    echo "SMTP Port: $SMTP_PORT"
    echo "SMTP User: $SMTP_USER"
    echo "Alert From: $ALERT_FROM"
    echo "Alert To: $ALERT_TO"
    echo
    
    echo "=========================================="
    echo "Application Configuration"
    echo "=========================================="
    echo "Frontend Origin: $FRONTEND_ORIGIN"
    echo "Poll Enabled: $POLL_ENABLED"
    echo "Poll Interval: $POLL_INTERVAL_MS ms"
    echo "Lookback Days: $LOOKBACK_DAYS"
    echo
    
    echo "=========================================="
    echo "Docker Configuration"
    echo "=========================================="
    echo "Backend Image: $BACKEND_IMAGE"
    echo "Frontend Image: $FRONTEND_IMAGE"
    echo
}

create_ssl_certificates() {
    log_info "Setting up SSL certificates..."
    
    local ssl_dir="${APP_DIR}/infra/docker/ssl"
    mkdir -p "$ssl_dir"
    
    read -p "Do you want to generate self-signed SSL certificates? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Generating self-signed SSL certificates..."
        
        # Generate private key
        openssl genrsa -out "$ssl_dir/key.pem" 2048
        
        # Generate certificate
        openssl req -new -x509 -key "$ssl_dir/key.pem" -out "$ssl_dir/cert.pem" -days 365 -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        # Set permissions
        chmod 600 "$ssl_dir/key.pem"
        chmod 644 "$ssl_dir/cert.pem"
        
        log_success "SSL certificates generated"
    else
        log_info "Skipping SSL certificate generation"
    fi
}

setup_monitoring() {
    log_info "Setting up monitoring configuration..."
    
    # Create monitoring directory
    local monitoring_dir="${APP_DIR}/monitoring"
    mkdir -p "$monitoring_dir"
    
    # Create CloudWatch configuration
    cat > "$monitoring_dir/cloudwatch-config.json" << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/todo-manager/application.log",
            "log_group_name": "/aws/ec2/todo-manager/application",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "TodoManager",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF
    
    log_success "Monitoring configuration created"
}

create_backup_script() {
    log_info "Creating backup script..."
    
    cat > "${APP_DIR}/backup.sh" << 'EOF'
#!/bin/bash

# Backup script for Todo Manager
BACKUP_DIR="/opt/todo-manager-backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="todo-manager-backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude="node_modules" \
    --exclude=".git" \
    --exclude="backups" \
    /opt/todo-manager

echo "Backup created: $BACKUP_DIR/$BACKUP_FILE"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "todo-manager-backup-*.tar.gz" -mtime +7 -delete
EOF
    
    chmod +x "${APP_DIR}/backup.sh"
    log_success "Backup script created"
}

# Main execution
main() {
    echo "=========================================="
    echo "Todo Manager Application Configuration"
    echo "=========================================="
    echo
    
    check_requirements
    create_env_file
    
    echo "Please provide the following configuration details:"
    echo
    
    configure_database
    configure_github
    configure_email
    configure_application
    configure_docker_images
    
    echo
    log_info "Additional configuration options:"
    create_ssl_certificates
    setup_monitoring
    create_backup_script
    
    echo
    if validate_configuration; then
        show_configuration
        log_success "Application configuration completed successfully!"
        echo
        echo "Next steps:"
        echo "1. Review the configuration above"
        echo "2. Run the deployment script: ./deploy.sh"
        echo "3. Check application health: ./health-check.sh"
    else
        log_error "Configuration validation failed. Please fix the errors and run again."
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --show|-s)
        if [ -f "$ENV_FILE" ]; then
            set -a
            source "$ENV_FILE"
            set +a
            show_configuration
        else
            log_error "Configuration file not found: $ENV_FILE"
            exit 1
        fi
        ;;
    --validate|-v)
        if [ -f "$ENV_FILE" ]; then
            set -a
            source "$ENV_FILE"
            set +a
            validate_configuration
        else
            log_error "Configuration file not found: $ENV_FILE"
            exit 1
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --show, -s       Show current configuration"
        echo "  --validate, -v   Validate current configuration"
        echo "  --help, -h       Show this help message"
        echo
        echo "Examples:"
        echo "  $0               Interactive configuration"
        echo "  $0 --show        Show current configuration"
        echo "  $0 --validate    Validate configuration"
        ;;
    *)
        main
        ;;
esac
