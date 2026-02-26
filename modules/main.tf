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
  private_subnet_ids           = module.network.private_subnet_ids
  splunk_instance_profile_name = module.security.splunk_instance_profile_name
  ami_id                       = data.aws_ami.amazon_linux.id
  splunk_version               = var.splunk_version
  splunk_build                 = var.splunk_build
}

# Route private subnet traffic through NAT instance
# This wires the compute module's NAT instance to the network module's private route table
resource "aws_route" "private_nat" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.compute.nat_primary_network_interface_id

}
