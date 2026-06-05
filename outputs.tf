output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.stock_analyzer.id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.stock_analyzer.arn
}

output "elastic_ip" {
  description = "Elastic IP address for accessing the instance"
  value       = aws_eip.stock_analyzer.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.stock_analyzer.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_name" {
  description = "Security group name"
  value       = aws_security_group.ec2_sg.name
}

output "ssh_connection_string" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/key.pem ubuntu@${aws_eip.stock_analyzer.public_ip}"
}

output "iam_role_name" {
  description = "IAM role name for EC2 instance"
  value       = aws_iam_role.ec2_role.name
}

output "start_lambda_function_name" {
  description = "Lambda function name for starting the instance"
  value       = var.enable_scheduling ? aws_lambda_function.start_lambda[0].function_name : "N/A"
}

output "stop_lambda_function_name" {
  description = "Lambda function name for stopping the instance"
  value       = var.enable_scheduling ? aws_lambda_function.stop_lambda[0].function_name : "N/A"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for EC2 instance"
  value       = aws_cloudwatch_log_group.ec2_logs.name
}

output "start_eventbridge_rule" {
  description = "EventBridge rule name for start schedule"
  value       = var.enable_scheduling ? aws_cloudwatch_event_rule.start_rule[0].name : "N/A"
}

output "stop_eventbridge_rule" {
  description = "EventBridge rule name for stop schedule"
  value       = var.enable_scheduling ? aws_cloudwatch_event_rule.stop_rule[0].name : "N/A"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "ami_name" {
  description = "AMI name"
  value       = data.aws_ami.ubuntu.name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "schedule_summary" {
  description = "Summary of scheduling configuration"
  value = var.enable_scheduling ? {
    start_time           = "9:00 AM IST (03:30 UTC)"
    stop_time            = "5:00 PM IST (11:30 UTC)"
    days                 = "Monday to Friday"
    weekends_shutdown    = true
    start_cron           = "30 3 ? * MON-FRI *"
    stop_cron            = "30 11 ? * MON-FRI *"
  } : { scheduling_enabled = false }
}
