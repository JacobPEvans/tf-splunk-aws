# Comprehensive monitoring and logging module
# Includes CloudWatch, syslog servers, and log aggregation for Splunk

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where monitoring resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for monitoring deployment"
  type        = list(string)
}

variable "syslog_config" {
  description = "Configuration for syslog servers"
  type = object({
    enabled       = bool
    instance_type = string
    count         = number
    disk_size     = number
    ami_id        = string
  })
  default = {
    enabled       = false
    instance_type = "t3.medium"
    count         = 1
    disk_size     = 50
    ami_id        = "ami-0c02fb55956c7d316"
  }
}

variable "cloudwatch_config" {
  description = "Configuration for CloudWatch monitoring"
  type = object({
    log_retention_days = number
    enable_insights    = bool
    custom_metrics     = bool
  })
  default = {
    log_retention_days = 7
    enable_insights    = true
    custom_metrics     = true
  }
}

variable "splunk_indexer_ips" {
  description = "List of Splunk indexer IP addresses for log forwarding"
  type        = list(string)
  default     = []
}

variable "log_sources" {
  description = "Map of log sources to monitor"
  type = map(object({
    log_group_name = string
    filter_pattern = string
    retention_days = number
  }))
  default = {}
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# Security Group for monitoring resources
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.environment}-monitoring-"
  vpc_id      = var.vpc_id

  # Syslog (TCP/UDP 514)
  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Syslog TCP"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Syslog UDP"
  }

  # SNMP (161/162)
  ingress {
    from_port   = 161
    to_port     = 162
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SNMP"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-monitoring-sg"
  })
}

# IAM Role for monitoring instances
resource "aws_iam_role" "monitoring" {
  name = "${var.environment}-monitoring-role"

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

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.environment}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

# Attach CloudWatch and SSM policies
resource "aws_iam_role_policy_attachment" "monitoring_cloudwatch" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Syslog Servers (if enabled)
resource "aws_instance" "syslog" {
  count = var.syslog_config.enabled ? var.syslog_config.count : 0

  ami                    = var.syslog_config.ami_id
  instance_type          = var.syslog_config.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.syslog_config.disk_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/syslog-userdata.sh", {
    environment       = var.environment
    splunk_indexer_ips = var.splunk_indexer_ips
    instance_index    = count.index
  }))

  tags = merge(local.common_tags, {
    Name = "${var.environment}-syslog-${count.index + 1}"
    Role = "syslog-server"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "custom" {
  for_each = var.log_sources

  name              = each.value.log_group_name
  retention_in_days = each.value.retention_days

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-logs"
  })
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "custom" {
  for_each = var.log_sources

  name           = "${var.environment}-${each.key}-filter"
  log_group_name = aws_cloudwatch_log_group.custom[each.key].name
  pattern        = each.value.filter_pattern

  metric_transformation {
    name      = "${each.key}_error_count"
    namespace = "${var.environment}/Application"
    value     = "1"
  }
}

# CloudWatch Alarms for critical metrics
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  for_each = var.log_sources

  alarm_name          = "${var.environment}-${each.key}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${each.key}_error_count"
  namespace           = "${var.environment}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors error rate for ${each.key}"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-alarm"
  })
}

# SNS Topic for notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-monitoring-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alerts"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-infrastructure-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization"],
            [".", "NetworkIn"],
            [".", "NetworkOut"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/lambda/${var.environment}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region  = data.aws_region.current.name
          title   = "Recent Log Events"
        }
      }
    ]
  })
}

# Data sources
data "aws_region" "current" {}