# Dev environment configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "file://C:/git/tf-splunk-aws/modules"
}

inputs = {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  # Instance sizing
  nat_instance_type       = "t3.nano"
  splunk_instance_type    = "t3.small"
  splunk_root_volume_size = 20
  splunk_data_volume_size = 50

  # Optional: Add your key pair name for SSH access
  # key_pair_name = "your-key-pair-name"

  # Splunk configuration
  splunk_admin_password = "SecurePassword123!"
}
