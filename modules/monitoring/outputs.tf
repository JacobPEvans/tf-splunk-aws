# Monitoring module outputs

output "syslog_instances" {
  description = "Syslog server instance details"
  value = var.syslog_config.enabled ? {
    ids         = aws_instance.syslog[*].id
    private_ips = aws_instance.syslog[*].private_ip
    public_ips  = aws_instance.syslog[*].public_ip
  } : null
}

output "security_group_id" {
  description = "Monitoring security group ID"
  value       = aws_security_group.monitoring.id
}

output "cloudwatch_log_groups" {
  description = "Created CloudWatch log groups"
  value = {
    for k, v in aws_cloudwatch_log_group.custom : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "iam_role_arn" {
  description = "Monitoring IAM role ARN"
  value       = aws_iam_role.monitoring.arn
}
