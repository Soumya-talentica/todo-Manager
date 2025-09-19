# Outputs for Todo Manager Infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_web_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "security_group_ssh_id" {
  description = "ID of the SSH security group"
  value       = aws_security_group.ssh.id
}

output "security_group_database_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_eip ? aws_eip.main[0].public_ip : null
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "application_url" {
  description = "URL to access the application"
  value       = var.create_eip ? "http://${aws_eip.main[0].public_ip}" : "http://${aws_instance.main.public_ip}"
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_pair_name != "" ? var.key_pair_name : "${var.project_name}-key"}.pem ubuntu@${var.create_eip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip}"
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    application = aws_cloudwatch_log_group.app_logs.name
    system      = aws_cloudwatch_log_group.system_logs.name
  }
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT
    To deploy the application:
    
    1. SSH into the instance:
       ${var.create_eip ? "ssh -i ${var.key_pair_name != "" ? var.key_pair_name : "${var.project_name}-key"}.pem ubuntu@${aws_eip.main[0].public_ip}" : "ssh -i ${var.key_pair_name != "" ? var.key_pair_name : "${var.project_name}-key"}.pem ubuntu@${aws_instance.main.public_ip}"}
    
    2. Clone your repository:
       git clone https://github.com/${var.github_owner}/${var.github_repo}.git
       cd ${var.github_repo}
    
    3. Copy environment variables:
       cp infra/docker/.env.example .env
       # Edit .env with your configuration
    
    4. Deploy with Docker Compose:
       docker-compose -f infra/docker/docker-compose.prod.yml up -d
    
    5. Check application status:
       curl http://${var.create_eip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip}/health
    
    Application will be available at: ${var.create_eip ? "http://${aws_eip.main[0].public_ip}" : "http://${aws_instance.main.public_ip}"}
  EOT
}
