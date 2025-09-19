#!/bin/bash

# User data script for Todo Manager EC2 instance
# This script sets up Docker, CloudWatch agent, and prepares the environment

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    wget \
    git \
    htop \
    jq

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/${project_name}/system",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "/aws/ec2/${project_name}/application",
            "log_stream_name": "{instance_id}-docker",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create application directory
mkdir -p /opt/${project_name}
chown ubuntu:ubuntu /opt/${project_name}

# Create Docker log rotation
cat > /etc/logrotate.d/docker << 'EOF'
/var/log/docker.log {
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

# Configure Docker logging
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker to apply logging configuration
systemctl restart docker

# Create deployment script
cat > /opt/${project_name}/deploy.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_NAME="${project_name}"
APP_DIR="/opt/${project_name}"

echo "Starting deployment of $PROJECT_NAME..."

# Navigate to application directory
cd $APP_DIR

# Check if docker-compose.prod.yml exists
if [ ! -f "infra/docker/docker-compose.prod.yml" ]; then
    echo "Error: docker-compose.prod.yml not found!"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found! Please create it from .env.example"
    exit 1
fi

# Pull latest images (if using ECR)
echo "Pulling latest images..."
docker-compose -f infra/docker/docker-compose.prod.yml pull

# Stop existing containers
echo "Stopping existing containers..."
docker-compose -f infra/docker/docker-compose.prod.yml down

# Start new containers
echo "Starting new containers..."
docker-compose -f infra/docker/docker-compose.prod.yml up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Health check
echo "Performing health check..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Application is healthy!"
else
    echo "❌ Health check failed!"
    docker-compose -f infra/docker/docker-compose.prod.yml logs
    exit 1
fi

echo "Deployment completed successfully!"
EOF

chmod +x /opt/${project_name}/deploy.sh
chown ubuntu:ubuntu /opt/${project_name}/deploy.sh

# Create health check script
cat > /opt/${project_name}/health-check.sh << 'EOF'
#!/bin/bash

echo "=== Todo Manager Health Check ==="
echo "Timestamp: $(date)"
echo

# Check Docker status
echo "Docker Status:"
systemctl is-active docker
echo

# Check running containers
echo "Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

# Check application health
echo "Application Health:"
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Frontend: OK"
else
    echo "❌ Frontend: FAILED"
fi

if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Backend API: OK"
else
    echo "❌ Backend API: FAILED"
fi

# Check database connection
if docker exec todo-manager-db-1 pg_isready -U todo > /dev/null 2>&1; then
    echo "✅ Database: OK"
else
    echo "❌ Database: FAILED"
fi

echo
echo "=== System Resources ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
echo
echo "Memory Usage:"
free -h
echo
echo "Disk Usage:"
df -h /
EOF

chmod +x /opt/${project_name}/health-check.sh
chown ubuntu:ubuntu /opt/${project_name}/health-check.sh

# Create systemd service for application
cat > /etc/systemd/system/${project_name}.service << EOF
[Unit]
Description=Todo Manager Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/${project_name}
ExecStart=/opt/${project_name}/deploy.sh
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable ${project_name}.service

# Create log directory
mkdir -p /var/log/${project_name}
chown ubuntu:ubuntu /var/log/${project_name}

# Set up log rotation for application logs
cat > /etc/logrotate.d/${project_name} << EOF
/var/log/${project_name}/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 ubuntu ubuntu
}
EOF

# Create a welcome message
cat > /opt/${project_name}/README.txt << 'EOF'
Todo Manager Infrastructure Setup Complete!

This EC2 instance has been configured with:
- Docker and Docker Compose
- CloudWatch agent for monitoring
- Application deployment scripts
- Health check utilities

Next steps:
1. Clone your repository: git clone <your-repo-url>
2. Copy environment variables: cp infra/docker/.env.example .env
3. Edit .env with your configuration
4. Deploy: ./deploy.sh

Useful commands:
- Check health: ./health-check.sh
- View logs: docker-compose -f infra/docker/docker-compose.prod.yml logs
- Restart app: sudo systemctl restart ${project_name}

For support, check the CloudWatch logs or contact the DevOps team.
EOF

chown ubuntu:ubuntu /opt/${project_name}/README.txt

# Signal completion
echo "User data script completed successfully" > /var/log/user-data.log
