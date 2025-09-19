#!/bin/bash

# Health Check Script for Todo Manager
# This script performs comprehensive health checks on the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="todo-manager"
DOCKER_COMPOSE_FILE="infra/docker/docker-compose.prod.yml"
HEALTH_ENDPOINTS=(
    "http://localhost/health"
    "http://localhost:5000/health"
)

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

check_docker_status() {
    log_info "Checking Docker status..."
    
    if ! systemctl is-active --quiet docker; then
        log_error "Docker is not running"
        return 1
    fi
    
    log_success "Docker is running"
}

check_containers() {
    log_info "Checking container status..."
    
    local containers=("todo-manager-nginx" "todo-manager-frontend" "todo-manager-backend" "todo-manager-db")
    local all_healthy=true
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            local status=$(docker ps --format "{{.Status}}" --filter "name=$container")
            if [[ $status == *"healthy"* ]] || [[ $status == *"Up"* ]]; then
                log_success "Container $container: $status"
            else
                log_warning "Container $container: $status"
                all_healthy=false
            fi
        else
            log_error "Container $container is not running"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        log_success "All containers are healthy"
        return 0
    else
        log_error "Some containers are not healthy"
        return 1
    fi
}

check_health_endpoints() {
    log_info "Checking health endpoints..."
    
    local all_healthy=true
    
    for endpoint in "${HEALTH_ENDPOINTS[@]}"; do
        if curl -f -s "$endpoint" > /dev/null 2>&1; then
            log_success "Health check passed: $endpoint"
        else
            log_error "Health check failed: $endpoint"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        log_success "All health endpoints are responding"
        return 0
    else
        log_error "Some health endpoints are not responding"
        return 1
    fi
}

check_database_connection() {
    log_info "Checking database connection..."
    
    if docker exec todo-manager-db-1 pg_isready -U todo -d tododb > /dev/null 2>&1; then
        log_success "Database connection is healthy"
        return 0
    else
        log_error "Database connection failed"
        return 1
    fi
}

check_api_endpoints() {
    log_info "Checking API endpoints..."
    
    local api_endpoints=(
        "http://localhost/api/tasks"
        "http://localhost/api/metrics/summary"
    )
    
    local all_healthy=true
    
    for endpoint in "${api_endpoints[@]}"; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")
        if [ "$response" = "200" ]; then
            log_success "API endpoint OK: $endpoint"
        else
            log_warning "API endpoint returned $response: $endpoint"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        log_success "All API endpoints are responding"
        return 0
    else
        log_warning "Some API endpoints are not responding correctly"
        return 1
    fi
}

check_system_resources() {
    log_info "Checking system resources..."
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage < 80" | bc -l) )); then
        log_success "CPU usage: ${cpu_usage}%"
    else
        log_warning "CPU usage is high: ${cpu_usage}%"
    fi
    
    # Memory usage
    local memory_info=$(free | grep Mem)
    local total_mem=$(echo $memory_info | awk '{print $2}')
    local used_mem=$(echo $memory_info | awk '{print $3}')
    local memory_percent=$((used_mem * 100 / total_mem))
    
    if [ $memory_percent -lt 80 ]; then
        log_success "Memory usage: ${memory_percent}%"
    else
        log_warning "Memory usage is high: ${memory_percent}%"
    fi
    
    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ $disk_usage -lt 80 ]; then
        log_success "Disk usage: ${disk_usage}%"
    else
        log_warning "Disk usage is high: ${disk_usage}%"
    fi
}

check_logs() {
    log_info "Checking recent logs for errors..."
    
    local error_count=0
    
    # Check Docker logs for errors
    if docker logs todo-manager-backend-1 2>&1 | grep -i error | tail -5; then
        log_warning "Found errors in backend logs"
        ((error_count++))
    fi
    
    if docker logs todo-manager-frontend-1 2>&1 | grep -i error | tail -5; then
        log_warning "Found errors in frontend logs"
        ((error_count++))
    fi
    
    if docker logs todo-manager-db-1 2>&1 | grep -i error | tail -5; then
        log_warning "Found errors in database logs"
        ((error_count++))
    fi
    
    if [ $error_count -eq 0 ]; then
        log_success "No recent errors found in logs"
    else
        log_warning "Found $error_count services with recent errors"
    fi
}

check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    # Check if ports are listening
    local ports=(80 443 5000 5432)
    
    for port in "${ports[@]}"; do
        if netstat -tlnp | grep -q ":$port "; then
            log_success "Port $port is listening"
        else
            log_warning "Port $port is not listening"
        fi
    done
}

show_detailed_status() {
    log_info "Detailed application status:"
    echo
    echo "=========================================="
    echo "Container Status"
    echo "=========================================="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
    
    echo "=========================================="
    echo "Resource Usage"
    echo "=========================================="
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)"
    echo
    echo "Memory Usage:"
    free -h
    echo
    echo "Disk Usage:"
    df -h /
    echo
    
    echo "=========================================="
    echo "Network Status"
    echo "=========================================="
    netstat -tlnp | grep -E ":(80|443|5000|5432) "
    echo
    
    echo "=========================================="
    echo "Recent Logs (last 10 lines)"
    echo "=========================================="
    echo "Backend logs:"
    docker logs --tail=10 todo-manager-backend-1 2>&1 | tail -10
    echo
    echo "Frontend logs:"
    docker logs --tail=10 todo-manager-frontend-1 2>&1 | tail -10
    echo
}

generate_health_report() {
    local report_file="/tmp/todo-manager-health-$(date +%Y%m%d-%H%M%S).txt"
    
    log_info "Generating health report: $report_file"
    
    {
        echo "Todo Manager Health Report"
        echo "Generated: $(date)"
        echo "=========================================="
        echo
        
        echo "System Information:"
        uname -a
        echo
        
        echo "Docker Version:"
        docker --version
        echo
        
        echo "Container Status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo
        
        echo "Resource Usage:"
        top -bn1 | grep "Cpu(s)"
        free -h
        df -h /
        echo
        
        echo "Network Status:"
        netstat -tlnp | grep -E ":(80|443|5000|5432) "
        echo
        
        echo "Application Logs:"
        docker logs --tail=50 todo-manager-backend-1 2>&1
        echo
        
    } > "$report_file"
    
    log_success "Health report generated: $report_file"
}

# Main execution
main() {
    echo "=========================================="
    echo "Todo Manager Health Check"
    echo "=========================================="
    echo "Timestamp: $(date)"
    echo
    
    local overall_status=0
    
    # Run all checks
    check_docker_status || overall_status=1
    check_containers || overall_status=1
    check_health_endpoints || overall_status=1
    check_database_connection || overall_status=1
    check_api_endpoints || overall_status=1
    check_system_resources
    check_logs
    check_network_connectivity
    
    echo
    echo "=========================================="
    
    if [ $overall_status -eq 0 ]; then
        log_success "Overall health status: HEALTHY"
    else
        log_error "Overall health status: UNHEALTHY"
    fi
    
    echo "=========================================="
    
    # Show detailed status if requested
    if [ "$1" = "--detailed" ] || [ "$1" = "-d" ]; then
        show_detailed_status
    fi
    
    # Generate report if requested
    if [ "$1" = "--report" ] || [ "$1" = "-r" ]; then
        generate_health_report
    fi
    
    exit $overall_status
}

# Handle command line arguments
case "${1:-}" in
    --detailed|-d)
        main --detailed
        ;;
    --report|-r)
        main --report
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --detailed, -d    Show detailed status information"
        echo "  --report, -r      Generate a detailed health report"
        echo "  --help, -h        Show this help message"
        echo
        echo "Examples:"
        echo "  $0                Basic health check"
        echo "  $0 --detailed     Detailed health check"
        echo "  $0 --report       Generate health report"
        ;;
    *)
        main
        ;;
esac
