# AWS EC2 Scheduler with Terraform

This Terraform configuration creates an EC2 t3.medium instance with the following features:

## Features
- **EC2 Instance**: Ubuntu t3.medium with scheduled start/stop
- **Static IP**: Elastic IP address for consistent access
- **Scheduled Operations**:
  - **Weekdays**: Starts at 9 AM, Stops at 5 PM (IST)
  - **Weekends**: Completely shut down
- **Security**:
  - Restricted security group rules
  - SSH access from specific IPs only
  - Internet access enabled
  - No unnecessary open ports
- **Monitoring**: CloudWatch integration for scheduling
- **IAM**: Proper roles and permissions for EC2 scheduling

## Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured with credentials
- SSH key pair created in AWS

## Architecture
```
VPC (Default or Custom)
├── EC2 Instance (t3.medium, Ubuntu)
├── Elastic IP (Static)
├── Security Group (Restricted)
├── IAM Role (EC2 Scheduling)
├── Lambda Functions (Start/Stop Scheduler)
└── EventBridge Rules (Cron-based Scheduling)
```

## Variables to Configure
- `aws_region`: AWS region (default: us-east-1)
- `instance_name`: EC2 instance name (default: stock-volatility-analyzer)
- `ami_owner`: Ubuntu AMI owner (default: Canonical)
- `allowed_ssh_ips`: List of IPs allowed for SSH access
- `key_pair_name`: Your AWS SSH key pair name
- `environment`: Environment tag (dev, prod, etc.)
- `enable_scheduling`: Enable/disable start-stop scheduling

## File Structure
```
.
├── README.md                 # Documentation
├── main.tf                   # Main EC2 and VPC resources
├── security.tf               # Security group and IAM configurations
├── scheduler.tf              # Lambda and EventBridge for scheduling
├── variables.tf              # Variable definitions
├── outputs.tf                # Output values
├── locals.tf                 # Local values and calculations
├── terraform.tfvars.example  # Example variables file
├── .gitignore                # Git ignore file
├── user_data.sh              # EC2 initialization script
├── lambda_start.py           # Lambda function to start EC2
└── lambda_stop.py            # Lambda function to stop EC2
```

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Update Variables
Copy and customize the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
aws_region           = "us-east-1"
instance_name        = "stock-volatility-analyzer"
allowed_ssh_ips      = "YOUR_IP/32"  # Replace with your IP
key_pair_name        = "your-key-pair"
environment          = "prod"
enable_scheduling    = true
```

### 3. Validate Configuration
```bash
terraform validate
terraform plan
```

### 4. Apply Configuration
```bash
terraform apply
```

### 5. Destroy Resources
```bash
terraform destroy
```

## Scheduling Details

### Start Schedule (Weekdays Only)
- **Time**: 9:00 AM IST (03:30 UTC)
- **Days**: Monday to Friday
- **Cron Expression**: `30 3 ? * MON-FRI *`

### Stop Schedule (Weekdays Only)
- **Time**: 5:00 PM IST (11:30 UTC)
- **Days**: Monday to Friday
- **Cron Expression**: `30 11 ? * MON-FRI *`

### Weekend Shutdown
- Instances automatically remain stopped on Saturdays and Sundays

## Security Features

### Security Group Rules
- **Inbound SSH (22)**: Restricted to specified IPs only
- **Inbound HTTP (80)**: Disabled (can be enabled if needed)
- **Inbound HTTPS (443)**: Disabled (can be enabled if needed)
- **Outbound**: All traffic allowed (for internet access and updates)

### IAM Permissions
- EC2 instance can perform scheduled operations
- Lambda functions have minimal required permissions
- No overly permissive policies

### Best Practices
- Instance metadata service v2 (IMDSv2) enforced
- Root volume encrypted
- Monitoring and logging enabled
- VPC security group isolation
- No public SSH access without IP whitelisting

## Accessing the Instance

### Get Instance Details
```bash
terraform output
```

### SSH Access
```bash
ssh -i /path/to/key.pem ubuntu@<elastic_ip>
```

### Instance Status
Check AWS Console or use AWS CLI:
```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=stock-volatility-analyzer"
```

## Monitoring

### CloudWatch Metrics
- CPU Utilization
- Network In/Out
- Status Checks
- Instance State Transitions

### Lambda Execution Logs
View Lambda execution logs in CloudWatch Logs:
```bash
aws logs tail /aws/lambda/stock-analyzer-start-lambda --follow
aws logs tail /aws/lambda/stock-analyzer-stop-lambda --follow
```

## Cost Estimation

**Approximate Monthly Cost:**
- EC2 t3.medium (8 hours/day, 5 days/week): ~$20-25
- Elastic IP (static): ~$3-4
- Lambda invocations: ~$0.20 (minimal)
- CloudWatch logs: ~$0.50
- **Total**: ~$25-30/month

## Customization

### Modify Start/Stop Times
Edit `scheduler.tf` and adjust the cron expressions:
```hcl
schedule_expression = "cron(30 3 ? * MON-FRI *)"  # 9:30 AM IST
```

Cron format: `minute hour day month day-of-week`
For IST times, add 5.5 hours to UTC (e.g., 3:30 UTC = 9 AM IST)

### Change Timezone
Update `locals.tf`:
```hcl
timezone = "Asia/Kolkata"  # or your timezone
```

### Allow Additional Ports
Modify `security.tf` to add ingress rules:
```hcl
ingress {
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Restrict as needed
}
```

### Disable Scheduling
Set in `terraform.tfvars`:
```hcl
enable_scheduling = false
```

## Troubleshooting

### Instance Not Starting
1. Check Lambda logs in CloudWatch
2. Verify IAM role permissions
3. Check EventBridge rules are enabled
4. Verify instance exists and is in correct state

### Can't SSH to Instance
1. Verify security group allows your IP
2. Check key pair is correct
3. Ensure instance is in running state
4. Verify Elastic IP is associated

### Elastic IP Not Associated
1. Run `terraform apply` again
2. Check no association conflict
3. Verify instance is running

### Lambda Functions Not Triggering
1. Check EventBridge rules are enabled
2. Verify Lambda permissions
3. Check CloudWatch Logs for errors
4. Verify IAM role for Lambda has EC2 permissions

## Important Notes

⚠️ **Important**: 
- Customize `allowed_ssh_ips` with your actual IP before deployment
- Keep your private key secure
- Regularly review security group rules
- Monitor CloudWatch logs for issues
- Set up billing alerts in AWS
- Backup sensitive data regularly

## Getting Your IP Address

```bash
# Unix/Linux/macOS
curl https://checkip.amazonaws.com

# Windows PowerShell
(Invoke-WebRequest https://checkip.amazonaws.com).Content
```

## Creating AWS Key Pair

```bash
aws ec2 create-key-pair --key-name stock-analyzer-key --region us-east-1 \
  --query 'KeyMaterial' --output text > stock-analyzer-key.pem

chmod 400 stock-analyzer-key.pem
```

## Quick Start

1. Clone or download this repository
2. Get your IP: `curl https://checkip.amazonaws.com`
3. Create SSH key pair in AWS
4. Copy `terraform.tfvars.example` to `terraform.tfvars`
5. Update `terraform.tfvars` with your values
6. Run `terraform init` && `terraform apply`
7. SSH to the instance using the Elastic IP

## Support

For issues or questions:
1. Check Terraform state: `terraform show`
2. Review CloudWatch logs
3. Verify AWS credentials and permissions
4. Check resource quotas in AWS

## License
MIT

---

**Last Updated**: 2026-06-05