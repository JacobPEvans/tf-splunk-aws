# Dev environment configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules"
}

inputs = {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  # Instance sizing
  nat_instance_type       = "t4g.nano"
  splunk_instance_type    = "t4g.small"
  splunk_root_volume_size = 20
  splunk_data_volume_size = 50

  # Optional: Add your key pair name for SSH access
  # key_pair_name = "your-key-pair-name"

  # SSH access: set to specific CIDRs to enable, empty list disables SSH entirely
  ssh_allowed_cidrs = []

  # Public access: place Splunk in public subnet with public IP
  # splunk_public_access = true
  # web_allowed_cidrs    = ["YOUR.IP/32"]
  # hec_allowed_cidrs    = ["YOUR.IP/32"]

  # Set SPLUNK_ADMIN_PASSWORD env var before running (e.g., via aws-vault or doppler)
  splunk_admin_password = get_env("SPLUNK_ADMIN_PASSWORD", "CHANGE_ME_USE_ENV_VAR")
}
