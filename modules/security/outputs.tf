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

output "splunk_password_ssm_name" {
  description = "SSM Parameter Store name for Splunk admin password"
  value       = aws_ssm_parameter.splunk_admin_password.name
}

output "internal_security_group_id" {
  description = "ID of the internal cluster security group (null when Cribl disabled)"
  value       = try(aws_security_group.internal[0].id, null)
}

output "cribl_security_group_id" {
  description = "ID of the Cribl security group (null when Cribl disabled)"
  value       = try(aws_security_group.cribl[0].id, null)
}

output "cribl_instance_profile_name" {
  description = "Name of the Cribl IAM instance profile (null when Cribl disabled)"
  value       = try(aws_iam_instance_profile.cribl[0].name, null)
}
