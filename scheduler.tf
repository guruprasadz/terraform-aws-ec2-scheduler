# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name        = "${var.instance_name}-lambda-role"
  description = "IAM role for Lambda scheduling functions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.instance_name}-lambda-role"
  }
}

# IAM Policy for Lambda to start/stop EC2 instances
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name   = "${var.instance_name}-lambda-ec2-policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Control"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.stock_analyzer.id}"
      },
      {
        Sid    = "AllowLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Lambda function to start EC2 instance
resource "aws_lambda_function" "start_lambda" {
  count            = var.enable_scheduling ? 1 : 0
  filename         = data.archive_file.start_lambda_zip.output_path
  function_name    = "${var.instance_name}-start-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.start_lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.stock_analyzer.id
      ACTION      = "start"
    }
  }

  tags = {
    Name = "${var.instance_name}-start-lambda"
  }
}

# Lambda function to stop EC2 instance
resource "aws_lambda_function" "stop_lambda" {
  count            = var.enable_scheduling ? 1 : 0
  filename         = data.archive_file.stop_lambda_zip.output_path
  function_name    = "${var.instance_name}-stop-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.stop_lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.stock_analyzer.id
      ACTION      = "stop"
    }
  }

  tags = {
    Name = "${var.instance_name}-stop-lambda"
  }
}

# Archive Lambda function code (Start)
data "archive_file" "start_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_start.py"
  output_path = "${path.module}/lambda_start.zip"
}

# Archive Lambda function code (Stop)
data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_stop.py"
  output_path = "${path.module}/lambda_stop.zip"
}

# EventBridge Rule for starting instance (9 AM IST = 03:30 UTC, Weekdays)
resource "aws_cloudwatch_event_rule" "start_rule" {
  count               = var.enable_scheduling ? 1 : 0
  name                = "${var.instance_name}-start-rule"
  description         = "Start ${var.instance_name} at 9 AM IST on weekdays"
  schedule_expression = "cron(30 3 ? * MON-FRI *)"
  is_enabled          = true

  tags = {
    Name = "${var.instance_name}-start-rule"
  }
}

# EventBridge Rule for stopping instance (5 PM IST = 11:30 UTC, Weekdays)
resource "aws_cloudwatch_event_rule" "stop_rule" {
  count               = var.enable_scheduling ? 1 : 0
  name                = "${var.instance_name}-stop-rule"
  description         = "Stop ${var.instance_name} at 5 PM IST on weekdays"
  schedule_expression = "cron(30 11 ? * MON-FRI *)"
  is_enabled          = true

  tags = {
    Name = "${var.instance_name}-stop-rule"
  }
}

# EventBridge Target for start Lambda
resource "aws_cloudwatch_event_target" "start_target" {
  count     = var.enable_scheduling ? 1 : 0
  rule      = aws_cloudwatch_event_rule.start_rule[0].name
  target_id = "${var.instance_name}-start-target"
  arn       = aws_lambda_function.start_lambda[0].arn
}

# EventBridge Target for stop Lambda
resource "aws_cloudwatch_event_target" "stop_target" {
  count     = var.enable_scheduling ? 1 : 0
  rule      = aws_cloudwatch_event_rule.stop_rule[0].name
  target_id = "${var.instance_name}-stop-target"
  arn       = aws_lambda_function.stop_lambda[0].arn
}

# Lambda permission for EventBridge to invoke start function
resource "aws_lambda_permission" "start_lambda_permission" {
  count         = var.enable_scheduling ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rule[0].arn
}

# Lambda permission for EventBridge to invoke stop function
resource "aws_lambda_permission" "stop_lambda_permission" {
  count         = var.enable_scheduling ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rule[0].arn
}

# CloudWatch Log Group for start Lambda
resource "aws_cloudwatch_log_group" "start_lambda_logs" {
  count             = var.enable_scheduling ? 1 : 0
  name              = "/aws/lambda/${var.instance_name}-start-lambda"
  retention_in_days = 7

  tags = {
    Name = "${var.instance_name}-start-lambda-logs"
  }
}

# CloudWatch Log Group for stop Lambda
resource "aws_cloudwatch_log_group" "stop_lambda_logs" {
  count             = var.enable_scheduling ? 1 : 0
  name              = "/aws/lambda/${var.instance_name}-stop-lambda"
  retention_in_days = 7

  tags = {
    Name = "${var.instance_name}-stop-lambda-logs"
  }
}
