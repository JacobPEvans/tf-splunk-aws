# Security Module - Security Groups and IAM
# Handles all security-related resources for Splunk AWS deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Local values for consistent tagging
locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# NAT Instance Security Group
resource "aws_security_group" "nat_instance" {
  name        = "${var.environment}-nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id

  # Allow HTTP outbound
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS outbound
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic from private subnets (for NAT functionality)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # SSH access (optional, if key pair provided)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-instance-sg"
  })
}

# Splunk Security Group
resource "aws_security_group" "splunk" {
  name        = "${var.environment}-splunk-sg"
  description = "Security group for Splunk instances"
  vpc_id      = var.vpc_id

  # Splunk Web (8000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  # Splunk Forwarder (9997)
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  # Splunk Management (8089)
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  # SSH access (optional, if key pair provided)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr_blocks
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-sg"
  })
}

# IAM Role for Splunk Instance
resource "aws_iam_role" "splunk_instance" {
  name = "${var.environment}-splunk-instance-role"

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

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-instance-role"
  })
}

# IAM Policy for Splunk Instance (basic EC2 and SSM access)
resource "aws_iam_role_policy" "splunk_instance" {
  name = "${var.environment}-splunk-instance-policy"
  role = aws_iam_role.splunk_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for Splunk
resource "aws_iam_instance_profile" "splunk" {
  name = "${var.environment}-splunk-instance-profile"
  role = aws_iam_role.splunk_instance.name

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-instance-profile"
  })
}
