# Splunk module outputs

output "indexer_instances" {
  description = "Splunk indexer instance details"
  value = {
    ids         = aws_instance.indexer[*].id
    private_ips = aws_instance.indexer[*].private_ip
    public_ips  = aws_instance.indexer[*].public_ip
  }
}

output "search_head_instances" {
  description = "Splunk search head instance details"
  value = {
    ids         = aws_instance.search_head[*].id
    private_ips = aws_instance.search_head[*].private_ip
    public_ips  = aws_instance.search_head[*].public_ip
  }
}

output "forwarder_instances" {
  description = "Universal forwarder instance details"
  value = {
    ids         = aws_instance.forwarder[*].id
    private_ips = aws_instance.forwarder[*].private_ip
    public_ips  = aws_instance.forwarder[*].public_ip
  }
}

output "security_group_id" {
  description = "ID of the Splunk security group"
  value       = aws_security_group.splunk.id
}

output "iam_role_arn" {
  description = "ARN of the Splunk IAM role"
  value       = aws_iam_role.splunk.arn
}

output "splunk_web_urls" {
  description = "URLs to access Splunk Web interface"
  value       = [for ip in aws_instance.search_head[*].private_ip : "https://${ip}:8000"]
}
