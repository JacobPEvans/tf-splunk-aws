# Terragrunt configuration for the dev environment

# Network module
terraform {
  source = "../../modules/network"
}

inputs = {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
}

# Security module
terraform {
  source = "../../modules/security"
}

inputs = {
  environment      = "dev"
  vpc_id           = "<VPC_ID_FROM_NETWORK_OUTPUT>"
  enable_guardduty = true
  enable_cloudtrail = true
}

# Compute module
terraform {
  source = "../../modules/compute"
}

inputs = {
  environment = "dev"
  vpc_id      = "<VPC_ID_FROM_NETWORK_OUTPUT>"
  subnet_ids  = "<PRIVATE_SUBNET_IDS_FROM_NETWORK_OUTPUT>"
}

# Splunk module
terraform {
  source = "../../modules/splunk"
}

inputs = {
  environment          = "dev"
  vpc_id               = "<VPC_ID_FROM_NETWORK_OUTPUT>"
  private_subnet_ids   = "<PRIVATE_SUBNET_IDS_FROM_NETWORK_OUTPUT>"
  splunk_admin_password = "SecurePassword123!"
}

# Monitoring module
terraform {
  source = "../../modules/monitoring"
}

inputs = {
  environment         = "dev"
  vpc_id              = "<VPC_ID_FROM_NETWORK_OUTPUT>"
  subnet_ids          = "<PRIVATE_SUBNET_IDS_FROM_NETWORK_OUTPUT>"
  splunk_indexer_ips  = "<INDEXER_IPS_FROM_SPLUNK_OUTPUT>"
}
