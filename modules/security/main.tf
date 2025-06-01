# Comprehensive security module for IAM, secrets management, and security groups
# Follows AWS security best practices and least privilege principles

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "splunk-aws"
}

variable "secrets" {
  description = "Map of secrets to create in AWS Secrets Manager"
  type = map(object({
    description = string
    secret_data = map(string)
  }))
  default = {}
  sensitive = true
}

variable "custom_policies" {
  description = "Map of custom IAM policies to create"
  type = map(object({
    description = string
    policy_document = string
  }))
  default = {}
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  }))
  default = {}
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.environment} environment encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail encryption"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.environment}-kms-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.environment}-${var.project_name}"
  target_key_id = aws_kms_key.main.key_id
}

# Secrets Manager
resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets

  name                    = "${var.environment}-${each.key}"
  description             = each.value.description
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}"
  })
}

resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode(each.value.secret_data)
}

# Custom IAM Policies
resource "aws_iam_policy" "custom" {
  for_each = var.custom_policies

  name        = "${var.environment}-${each.key}"
  description = each.value.description
  policy      = each.value.policy_document

  tags = local.common_tags
}

# Security Groups
resource "aws_security_group" "custom" {
  for_each = var.security_groups

  name_prefix = "${var.environment}-${each.key}-"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-sg"
  })
}

# Security Group Rules - Ingress
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for combo in flatten([
      for sg_key, sg_config in var.security_groups : [
        for rule_idx, rule in sg_config.ingress_rules : {
          sg_key    = sg_key
          rule_key  = "${sg_key}-ingress-${rule_idx}"
          rule      = rule
        }
      ]
    ]) : combo.rule_key => combo
  }

  type              = "ingress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  cidr_blocks       = each.value.rule.cidr_blocks
  description       = each.value.rule.description
  security_group_id = aws_security_group.custom[each.value.sg_key].id
}

# Security Group Rules - Egress
resource "aws_security_group_rule" "egress" {
  for_each = {
    for combo in flatten([
      for sg_key, sg_config in var.security_groups : [
        for rule_idx, rule in sg_config.egress_rules : {
          sg_key    = sg_key
          rule_key  = "${sg_key}-egress-${rule_idx}"
          rule      = rule
        }
      ]
    ]) : combo.rule_key => combo
  }

  type              = "egress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  cidr_blocks       = each.value.rule.cidr_blocks
  description       = each.value.rule.description
  security_group_id = aws_security_group.custom[each.value.sg_key].id
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false # Enable if using EKS
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-guardduty"
  })
}

# CloudTrail S3 Bucket
resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.environment}-${var.project_name}-cloudtrail-${random_id.bucket_suffix[0].hex}"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cloudtrail-bucket"
  })
}

resource "random_id" "bucket_suffix" {
  count       = var.enable_cloudtrail ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  count          = var.enable_cloudtrail ? 1 : 0
  name           = "${var.environment}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail[0].bucket
  kms_key_id     = aws_kms_key.main.arn

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cloudtrail"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# CloudTrail S3 Bucket Policy
resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
