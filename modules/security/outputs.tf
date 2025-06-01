# Security module outputs

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "KMS key alias name"
  value       = aws_kms_alias.main.name
}

output "secrets_manager_arns" {
  description = "ARNs of created secrets"
  value = {
    for k, v in aws_secretsmanager_secret.secrets : k => v.arn
  }
}

output "custom_policy_arns" {
  description = "ARNs of custom IAM policies"
  value = {
    for k, v in aws_iam_policy.custom : k => v.arn
  }
}

output "security_group_ids" {
  description = "IDs of created security groups"
  value = {
    for k, v in aws_security_group.custom : k => v.id
  }
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_bucket_name" {
  description = "CloudTrail S3 bucket name"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].bucket : null
}
