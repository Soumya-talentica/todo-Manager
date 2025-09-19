# Main Terraform configuration for Todo Manager Infrastructure

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Backend API (optional direct access)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_security_group" "ssh" {
  name_prefix = "${var.project_name}-ssh-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ssh-sg"
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# IAM Policy for CloudWatch
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "${var.project_name}-cloudwatch-policy"
  description = "Policy for CloudWatch logs and metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for ECR
resource "aws_iam_policy" "ecr_policy" {
  name        = "${var.project_name}-ecr-policy"
  description = "Policy for ECR access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Key Pair (if not provided)
resource "aws_key_pair" "main" {
  count      = var.key_pair_name == "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.public_key

  tags = {
    Name = "${var.project_name}-key"
  }
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : aws_key_pair.main[0].key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id, aws_security_group.ssh.id, aws_security_group.database.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    aws_region   = var.aws_region
    account_id   = data.aws_caller_identity.current.account_id
  }))

  tags = {
    Name = "${var.project_name}-instance"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP
resource "aws_eip" "main" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}/application"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/${var.project_name}/system"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-system-logs"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-memory-alarm"
  }
}
