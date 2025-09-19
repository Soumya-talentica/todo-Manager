# Infrastructure as Code (IAC) for Todo Manager

This directory contains all the Infrastructure as Code (IAC) configurations and scripts needed to deploy the Todo Manager application to AWS EC2 using Terraform.

## 📁 Directory Structure

```
infra/
├── README.md                    # This file - comprehensive documentation
├── terraform/                   # Terraform configuration files
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── versions.tf             # Provider version constraints
│   ├── vpc.tf                  # VPC and networking configuration
│   ├── security-groups.tf      # Security group definitions
│   ├── ec2.tf                  # EC2 instance configuration
│   ├── iam.tf                  # IAM roles and policies
│   ├── monitoring.tf           # CloudWatch monitoring setup
│   └── terraform.tfvars.example # Example variables file
├── scripts/                    # Deployment and utility scripts
│   ├── deploy.sh              # Main deployment script
│   ├── setup-docker.sh        # Docker installation script
│   ├── configure-app.sh       # Application configuration script
│   └── health-check.sh        # Health check script
├── docker/                     # Docker-related configurations
│   ├── docker-compose.prod.yml # Production Docker Compose
│   └── .env.example           # Environment variables template
└── monitoring/                 # Monitoring configurations
    ├── cloudwatch-config.json # CloudWatch agent configuration
    └── log-groups.tf          # CloudWatch log groups
```

## 🏗️ Architecture Overview

The infrastructure deploys a **single EC2 instance** running the complete Todo Manager stack:

- **Frontend**: React app served via Nginx
- **Backend**: Node.js Express API
- **Database**: PostgreSQL container
- **Monitoring**: CloudWatch integration
- **Security**: VPC, Security Groups, IAM roles

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** (for local testing)
4. **Git** for cloning the repository

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

### 2. Set Up Terraform Variables

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Deploy Application

```bash
# Run the deployment script
cd ../scripts
chmod +x deploy.sh
./deploy.sh
```

## 📋 Configuration

### Required Variables

Edit `terraform/terraform.tfvars` with your values:

```hcl
# AWS Configuration
aws_region = "us-west-2"
project_name = "todo-manager"
environment = "dev"

# EC2 Configuration
instance_type = "t3.medium"
key_pair_name = "your-key-pair"
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production

# Application Configuration
github_owner = "your-github-username"
github_repo = "your-repo-name"
domain_name = "your-domain.com"  # Optional

# Database Configuration
db_password = "your-secure-password"

# Email Configuration (for CI/CD alerts)
smtp_host = "smtp.gmail.com"
smtp_user = "your-email@gmail.com"
smtp_password = "your-app-password"
alert_from = "your-email@gmail.com"
alert_to = "admin@yourcompany.com"
```

### Environment Variables

The application requires several environment variables. These are configured in `docker/.env.example`:

```bash
# Database
DB_HOST=db
DB_USER=todo
DB_PASSWORD=your-secure-password
DB_NAME=tododb
DB_PORT=5432

# GitHub Integration
GITHUB_OWNER=your-github-username
GITHUB_REPO=your-repo-name
GITHUB_TOKEN=your-github-token
GITHUB_WEBHOOK_SECRET=your-webhook-secret

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_SECURE=true
ALERT_FROM=your-email@gmail.com
ALERT_TO=admin@yourcompany.com

# Application
FRONTEND_ORIGIN=http://your-domain.com
POLL_ENABLED=true
POLL_INTERVAL_MS=60000
POLL_PER_PAGE=50
LOOKBACK_DAYS=30
```

## 🔧 Infrastructure Components

### VPC and Networking
- **VPC**: Custom VPC with public subnet
- **Internet Gateway**: For internet access
- **Route Table**: Routes traffic to internet gateway
- **Subnet**: Public subnet for EC2 instance

### Security Groups
- **Web Access**: Ports 80 (HTTP) and 443 (HTTPS)
- **SSH Access**: Port 22 for management
- **API Access**: Port 5000 for backend API
- **Database Access**: Port 5432 for PostgreSQL

### EC2 Instance
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Storage**: 20GB gp3 EBS volume
- **OS**: Ubuntu 22.04 LTS
- **IAM Role**: For CloudWatch and ECR access

### IAM Roles and Policies
- **EC2 Instance Role**: CloudWatch and ECR access
- **CloudWatch Policy**: Logs and metrics permissions
- **ECR Policy**: Container registry access

### Monitoring
- **CloudWatch Agent**: System and application metrics
- **Log Groups**: Centralized logging
- **Alarms**: CPU, memory, and disk usage alerts

## 🐳 Docker Configuration

The application runs using Docker Compose with the following services:

- **frontend**: React app with Nginx
- **backend**: Node.js API server
- **db**: PostgreSQL database

### Production Docker Compose

The `docker/docker-compose.prod.yml` file is optimized for production:

- Health checks for all services
- Restart policies
- Resource limits
- Environment variable configuration

## 📊 Monitoring and Logging

### CloudWatch Integration

- **Metrics**: CPU, memory, disk usage
- **Logs**: Application logs, system logs
- **Alarms**: Automated alerts for critical issues

### Health Checks

- **Application Health**: `/health` endpoint
- **Database Health**: PostgreSQL connection check
- **Service Health**: Docker container status

## 🔒 Security Features

### Network Security
- VPC isolation
- Security groups with minimal required ports
- No direct database access from internet

### Access Control
- IAM roles with least privilege
- SSH key-based authentication
- Secure environment variable handling

### Application Security
- Rate limiting
- CORS configuration
- Helmet security headers
- Input validation

## 🚨 Troubleshooting

### Common Issues

1. **Terraform Apply Fails**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify region and availability zones
   aws ec2 describe-availability-zones
   ```

2. **EC2 Instance Not Accessible**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids <sg-id>
   
   # Verify key pair exists
   aws ec2 describe-key-pairs
   ```

3. **Application Not Starting**
   ```bash
   # SSH into instance
   ssh -i your-key.pem ubuntu@<instance-ip>
   
   # Check Docker status
   sudo docker ps
   sudo docker logs <container-name>
   ```

4. **Database Connection Issues**
   ```bash
   # Check database container
   sudo docker logs todo-manager-db-1
   
   # Verify environment variables
   sudo docker exec todo-manager-backend-1 env | grep DB_
   ```

### Log Locations

- **Application Logs**: CloudWatch Logs
- **System Logs**: `/var/log/syslog`
- **Docker Logs**: `docker logs <container>`
- **Terraform Logs**: `terraform.log`

## 💰 Cost Estimation

### Monthly Costs (us-west-2)

- **EC2 t3.medium**: ~$30
- **EBS 20GB gp3**: ~$2
- **Data Transfer**: ~$5-10
- **CloudWatch**: ~$5-15
- **Total**: ~$42-57/month

### Cost Optimization

- Use Spot Instances for development
- Implement auto-shutdown for non-production
- Monitor and optimize CloudWatch usage
- Use S3 for log storage if needed

## 🔄 CI/CD Integration

The infrastructure supports CI/CD through:

- **GitHub Actions**: Automated deployment
- **ECR Integration**: Container image storage
- **Webhook Support**: GitHub workflow monitoring
- **Health Checks**: Automated deployment verification

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)

## 🤝 Contributing

1. Make changes to Terraform files
2. Test with `terraform plan`
3. Update documentation
4. Submit pull request

## 📄 License

This infrastructure code is part of the Todo Manager project and follows the same license terms.
