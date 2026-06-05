locals {
  # Common naming convention
  name_prefix = "${var.instance_name}-${var.environment}"
  
  # Scheduling information
  schedule_info = {
    start_time        = "9:00 AM IST"
    stop_time         = "5:00 PM IST"
    start_cron_utc    = "cron(30 3 ? * MON-FRI *)"
    stop_cron_utc     = "cron(30 11 ? * MON-FRI *)"
    timezone          = "Asia/Kolkata"
    working_days      = "Monday to Friday"
    weekend_behavior  = "Stopped (No schedule)"
  }
  
  # Common tags
  common_tags = {
    Project     = "Stock Volatility Analyzer"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
    CostCenter  = "Development"
  }
}
