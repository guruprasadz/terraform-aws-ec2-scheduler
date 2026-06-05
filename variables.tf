variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1, ap-south-1)."
  }
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "stock-volatility-analyzer"

  validation {
    condition     = length(var.instance_name) <= 63 && can(regex("^[a-z0-9-]+$", var.instance_name))
    error_message = "Instance name must be lowercase, alphanumeric with hyphens, max 63 characters."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t3\\.(micro|small|medium|large|xlarge)$", var.instance_type))
    error_message = "Instance type must be a t3 family (e.g., t3.medium)."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 20 and 1000 GB."
  }
}

variable "ami_owner" {
  description = "AMI owner (Canonical for Ubuntu)"
  type        = string
  default     = "099720109477" # Canonical

  validation {
    condition     = can(regex("^\\d{12}$", var.ami_owner))
    error_message = "AMI owner must be a 12-digit AWS account ID."
  }
}

variable "key_pair_name" {
  description = "AWS EC2 key pair name for SSH access"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name cannot be empty."
  }
}

variable "allowed_ssh_ips" {
  description = "CIDR blocks allowed for SSH access (e.g., 203.0.113.0/32)"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.allowed_ssh_ips))
    error_message = "Must be a valid CIDR block (e.g., 203.0.113.0/32)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_scheduling" {
  description = "Enable start/stop scheduling for the EC2 instance"
  type        = bool
  default     = true
}

variable "timezone" {
  description = "Timezone for scheduling (not directly used in cron, but for reference)"
  type        = string
  default     = "Asia/Kolkata"
}
