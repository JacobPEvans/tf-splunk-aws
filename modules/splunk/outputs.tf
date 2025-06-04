# Splunk Module Outputs

output "splunk_instance_id" {
  description = "ID of the Splunk instance"
  value       = aws_instance.splunk.id
}

output "splunk_instance_private_ip" {
  description = "Private IP address of the Splunk instance"
  value       = aws_instance.splunk.private_ip
}

output "splunk_web_url" {
  description = "URL for Splunk Web interface (internal)"
  value       = "http://${aws_instance.splunk.private_ip}:8000"
}

output "splunk_cloudwatch_log_group" {
  description = "CloudWatch log group for Splunk instance"
  value       = aws_cloudwatch_log_group.splunk.name
}

output "splunk_app_log_group" {
  description = "CloudWatch log group for Splunk application logs"
  value       = aws_cloudwatch_log_group.splunk_app.name
}
