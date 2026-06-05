terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Stock-Volatility-Analyzer"
      ManagedBy   = "Terraform"
      CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}

# Data source for Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Elastic IP for static IP address
resource "aws_eip" "stock_analyzer" {
  instance = aws_instance.stock_analyzer.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-eip"
  }

  depends_on = [aws_instance.stock_analyzer]
}

# EC2 Instance
resource "aws_instance" "stock_analyzer" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  # IAM role for EC2 scheduling permissions
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Security group
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  # Enable IMDSv2 (Instance Metadata Service Version 2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  # Monitoring
  monitoring = true

  # User data script for initialization
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    instance_name = var.instance_name
  }))

  # Stop behavior
  instance_initiated_shutdown_behavior = "stop"

  tags = {
    Name = var.instance_name
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# CloudWatch Log Group for EC2 System Manager
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${var.instance_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.instance_name}-logs"
  }
}
