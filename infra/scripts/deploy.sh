#!/bin/bash

# Todo Manager Deployment Script
# This script deploys the Todo Manager application to the EC2 instance

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
DOCKER_COMPOSE_FILE="infra/docker/docker-compose.prod.yml"
ENV_FILE=".env"

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
    
    # Check if running as ubuntu user
    if [ "$USER" != "ubuntu" ]; then
        log_warning "This script should be run as the ubuntu user"
    fi
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker compose > /dev/null 2>&1; then
        log_error "docker-compose is not installed"
        exit 1
    fi
    
    log_success "Requirements check passed"
}

check_files() {
    log_info "Checking required files..."
    
    # Check if we're in the right directory
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        log_info "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found: $ENV_FILE"
        log_info "Please copy infra/docker/env.example to .env and configure it"
        exit 1
    fi
    
    log_success "Required files found"
}

validate_environment() {
    log_info "Validating environment configuration..."
    
    # Source the .env file
    set -a
    source .env
    set +a
    
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
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [ "${!var}" = "your-"* ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "Missing or invalid environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        log_info "Please update your .env file with proper values"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

backup_existing() {
    log_info "Backing up existing deployment..."
    
    if [ -d "$APP_DIR" ] && [ "$(ls -A $APP_DIR)" ]; then
        local backup_dir="/opt/${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Creating backup at $backup_dir"
        cp -r "$APP_DIR" "$backup_dir"
        log_success "Backup created: $backup_dir"
    fi
}

prepare_application() {
    log_info "Preparing application..."
    
    # Create application directory
    mkdir -p "$APP_DIR"
    
    # Copy application files
    log_info "Copying application files..."
    cp -r . "$APP_DIR/"
    
    # Set proper permissions
    chown -R ubuntu:ubuntu "$APP_DIR"
    chmod +x "$APP_DIR/infra/scripts"/*.sh
    
    log_success "Application prepared"
}

deploy_containers() {
    log_info "Deploying containers..."
    
    cd "$APP_DIR"
    
    # Pull latest images (if using ECR or custom registry)
    if [ -n "$BACKEND_IMAGE" ] || [ -n "$FRONTEND_IMAGE" ]; then
        log_info "Pulling latest images..."
        docker compose -f "$DOCKER_COMPOSE_FILE" pull
    fi
    
    # Stop existing containers
    log_info "Stopping existing containers..."
    docker compose -f "$DOCKER_COMPOSE_FILE" down || true
    
    # Remove unused images
    log_info "Cleaning up unused images..."
    docker image prune -f
    
    # Start new containers
    log_info "Starting new containers..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    log_success "Containers deployed"
}

wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Health check attempt $attempt/$max_attempts"
        
        # Check if all containers are running
        local running_containers=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps -q | wc -l)
        local healthy_containers=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -c "Up (healthy)")
        
        if [ "$running_containers" -gt 0 ] && [ "$healthy_containers" -gt 0 ]; then
            log_success "Services are ready"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "Services failed to start within expected time"
    return 1
}

perform_health_check() {
    log_info "Performing health check..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check frontend health
        if curl -f http://localhost/health > /dev/null 2>&1; then
            log_success "Frontend health check passed"
        else
            log_warning "Frontend health check failed (attempt $attempt/$max_attempts)"
        fi
        
        # Check backend health
        if curl -f http://localhost:5000/health > /dev/null 2>&1; then
            log_success "Backend health check passed"
        else
            log_warning "Backend health check failed (attempt $attempt/$max_attempts)"
        fi
        
        # Check database health
        if docker exec todo-manager-db-1 pg_isready -U todo > /dev/null 2>&1; then
            log_success "Database health check passed"
            log_success "All health checks passed!"
            return 0
        else
            log_warning "Database health check failed (attempt $attempt/$max_attempts)"
        fi
        
        sleep 5
        ((attempt++))
    done
    
    log_error "Health checks failed"
    return 1
}

show_deployment_info() {
    log_info "Deployment completed!"
    echo
    echo "=========================================="
    echo "Todo Manager Deployment Information"
    echo "=========================================="
    echo "Application URL: http://$(curl -s ifconfig.me)"
    echo "Health Check: http://$(curl -s ifconfig.me)/health"
    echo "API Endpoint: http://$(curl -s ifconfig.me)/api/"
    echo "Monitor Dashboard: http://$(curl -s ifconfig.me)/monitor"
    echo
    echo "Useful Commands:"
    echo "  View logs: docker compose -f $DOCKER_COMPOSE_FILE logs"
    echo "  Check status: docker compose -f $DOCKER_COMPOSE_FILE ps"
    echo "  Restart: docker compose -f $DOCKER_COMPOSE_FILE restart"
    echo "  Stop: docker compose -f $DOCKER_COMPOSE_FILE down"
    echo
    echo "Health Check Script: $APP_DIR/health-check.sh"
    echo "=========================================="
}

show_logs() {
    log_info "Showing recent logs..."
    echo
    docker compose -f "$DOCKER_COMPOSE_FILE" logs --tail=50
}

# Main execution
main() {
    echo "=========================================="
    echo "Todo Manager Deployment Script"
    echo "=========================================="
    echo
    
    check_requirements
    check_files
    validate_environment
    backup_existing
    prepare_application
    deploy_containers
    
    if wait_for_services; then
        if perform_health_check; then
            show_deployment_info
            log_success "Deployment completed successfully!"
        else
            log_error "Health checks failed"
            show_logs
            exit 1
        fi
    else
        log_error "Services failed to start"
        show_logs
        exit 1
    fi
}

# Run main function
main "$@"
