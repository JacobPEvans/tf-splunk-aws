# Root Module - Splunk AWS Infrastructure
# Orchestrates modular infrastructure components for cost-optimized Splunk deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS account identity - used for unique S3 bucket naming
data "aws_caller_identity" "current" {}

# Shared AMI data source - deduplicated from compute and splunk modules
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SmartStore S3 Bucket - remote storage for Splunk warm/cold index buckets
# Created at root level to break circular dependency: security needs ARN for IAM, splunk needs name for config
resource "aws_s3_bucket" "smartstore" {
  bucket = "${var.environment}-splunk-smartstore-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
    Name        = "${var.environment}-splunk-smartstore"
  }
}

resource "aws_s3_bucket_versioning" "smartstore" {
  bucket = aws_s3_bucket.smartstore.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "smartstore" {
  bucket = aws_s3_bucket.smartstore.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "smartstore" {
  bucket = aws_s3_bucket.smartstore.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "smartstore" {
  bucket = aws_s3_bucket.smartstore.id

  rule {
    id     = "smartstore-tiering"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Network Module
module "network" {
  source = "./network"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Security Module
module "security" {
  source = "./security"

  environment           = var.environment
  vpc_id                = module.network.vpc_id
  vpc_cidr_blocks       = [module.network.vpc_cidr_block]
  private_subnet_cidrs  = var.private_subnet_cidrs
  splunk_admin_password = var.splunk_admin_password
  ssh_allowed_cidrs     = var.ssh_allowed_cidrs
  hec_allowed_cidrs     = var.hec_allowed_cidrs
  web_allowed_cidrs     = var.web_allowed_cidrs
  smartstore_bucket_arn = aws_s3_bucket.smartstore.arn
}

# Compute Module (NAT Instance)
module "compute" {
  source = "./compute"

  environment           = var.environment
  nat_instance_type     = var.nat_instance_type
  key_pair_name         = var.key_pair_name
  nat_security_group_id = module.security.nat_security_group_id
  public_subnet_ids     = module.network.public_subnet_ids
  ami_id                = data.aws_ami.amazon_linux.id
}

# Splunk Module
module "splunk" {
  source = "./splunk"

  environment                  = var.environment
  splunk_instance_type         = var.splunk_instance_type
  splunk_root_volume_size      = var.splunk_root_volume_size
  splunk_data_volume_size      = var.splunk_data_volume_size
  splunk_password_ssm_name     = module.security.splunk_password_ssm_name
  key_pair_name                = var.key_pair_name
  splunk_security_group_id     = module.security.splunk_security_group_id
  subnet_ids                   = var.splunk_public_access ? module.network.public_subnet_ids : module.network.private_subnet_ids
  associate_public_ip_address  = var.splunk_public_access
  splunk_instance_profile_name = module.security.splunk_instance_profile_name
  ami_id                       = data.aws_ami.amazon_linux.id
  splunk_version               = var.splunk_version
  splunk_build                 = var.splunk_build
  smartstore_bucket_name       = aws_s3_bucket.smartstore.bucket
  enable_auto_lifecycle        = var.enable_auto_lifecycle
  auto_shutdown_minutes        = var.auto_shutdown_minutes
  lifecycle_interval_hours     = var.lifecycle_interval_hours
}

# Route private subnet traffic through NAT instance
# This wires the compute module's NAT instance to the network module's private route table
resource "aws_route" "private_nat" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.compute.nat_primary_network_interface_id

}
