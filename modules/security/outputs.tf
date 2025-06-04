# Security Module Outputs

output "nat_security_group_id" {
  description = "ID of the NAT instance security group"
  value       = aws_security_group.nat_instance.id
}

output "splunk_security_group_id" {
  description = "ID of the Splunk security group"
  value       = aws_security_group.splunk.id
}

output "splunk_instance_profile_name" {
  description = "Name of the Splunk IAM instance profile"
  value       = aws_iam_instance_profile.splunk.name
}

output "splunk_iam_role_arn" {
  description = "ARN of the Splunk IAM role"
  value       = aws_iam_role.splunk_instance.arn
}
