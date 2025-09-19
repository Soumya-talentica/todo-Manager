# Variables for Todo Manager Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "todo-manager"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps Team"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = ""
}

variable "public_key" {
  description = "Public key for EC2 access (used if key_pair_name is empty)"
  type        = string
  default     = ""
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_eip" {
  description = "Whether to create an Elastic IP"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

# Application Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

# Database Configuration
variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  default     = ""
}

# Email Configuration
variable "smtp_host" {
  description = "SMTP host for email notifications"
  type        = string
  default     = ""
}

variable "smtp_user" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alert_from" {
  description = "Email address for sending alerts"
  type        = string
  default     = ""
}

variable "alert_to" {
  description = "Email address for receiving alerts"
  type        = string
  default     = ""
}

# GitHub Configuration
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}

# Application Settings
variable "frontend_origin" {
  description = "Frontend origin URL"
  type        = string
  default     = ""
}

variable "poll_enabled" {
  description = "Enable GitHub polling"
  type        = bool
  default     = true
}

variable "poll_interval_ms" {
  description = "Polling interval in milliseconds"
  type        = number
  default     = 60000
}

variable "poll_per_page" {
  description = "Number of items per page for polling"
  type        = number
  default     = 50
}

variable "lookback_days" {
  description = "Number of days to look back for metrics"
  type        = number
  default     = 30
}
