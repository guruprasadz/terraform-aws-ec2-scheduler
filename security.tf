# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} EC2 instance"

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# Inbound SSH rule (restricted to specific IPs)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ec2_sg.id

  from_port       = 22
  to_port         = 22
  ip_protocol     = "tcp"
  cidr_ipv4       = var.allowed_ssh_ips
  description     = "SSH access from allowed IPs"

  tags = {
    Name = "ssh-inbound"
  }
}

# Outbound rule - allow all traffic (for internet access and updates)
resource "aws_vpc_security_group_egress_rule" "all_traffic" {
  security_group_id = aws_security_group.ec2_sg.id

  from_port       = -1
  to_port         = -1
  ip_protocol     = "-1" # All protocols
  cidr_ipv4       = "0.0.0.0/0"
  description     = "Allow all outbound traffic"

  tags = {
    Name = "all-outbound"
  }
}

# Optional: HTTP rule (disabled by default, uncomment if needed)
# resource "aws_vpc_security_group_ingress_rule" "http" {
#   security_group_id = aws_security_group.ec2_sg.id
#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
#   description       = "HTTP access"
#   tags = {
#     Name = "http-inbound"
#   }
# }

# Optional: HTTPS rule (disabled by default, uncomment if needed)
# resource "aws_vpc_security_group_ingress_rule" "https" {
#   security_group_id = aws_security_group.ec2_sg.id
#   from_port         = 443
#   to_port           = 443
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
#   description       = "HTTPS access"
#   tags = {
#     Name = "https-inbound"
#   }
# }

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name        = "${var.instance_name}-role"
  description = "IAM role for ${var.instance_name} EC2 instance"

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
    Name = "${var.instance_name}-role"
  }
}

# IAM Policy for EC2 to perform stop/start operations
resource "aws_iam_role_policy" "ec2_scheduler_policy" {
  name   = "${var.instance_name}-scheduler-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Operations"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.stock_analyzer.id}"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ec2_logs.arn}:*"
      },
      {
        Sid    = "AllowSSMAccess"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "ec2messages:GetMessages"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.ec2_role.name
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}
