# Root Module - Splunk AWS Infrastructure
# Orchestrates modular infrastructure components for cost-optimized Splunk deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  environment          = var.environment
  vpc_id               = module.network.vpc_id
  vpc_cidr_blocks      = [module.network.vpc_cidr_block]
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_ssh_access    = var.key_pair_name != null
}

# Compute Module (NAT Instance)
module "compute" {
  source = "./compute"

  environment           = var.environment
  nat_instance_type     = var.nat_instance_type
  key_pair_name         = var.key_pair_name
  nat_security_group_id = module.security.nat_security_group_id
  public_subnet_ids     = module.network.public_subnet_ids
}

# Splunk Module
module "splunk" {
  source = "./splunk"

  environment                  = var.environment
  splunk_instance_type         = var.splunk_instance_type
  splunk_root_volume_size      = var.splunk_root_volume_size
  splunk_data_volume_size      = var.splunk_data_volume_size
  splunk_admin_password        = var.splunk_admin_password
  key_pair_name                = var.key_pair_name
  splunk_security_group_id     = module.security.splunk_security_group_id
  private_subnet_ids           = module.network.private_subnet_ids
  splunk_instance_profile_name = module.security.splunk_instance_profile_name
}
