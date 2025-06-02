# Security module configuration for dev environment
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/security"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment      = "dev"
  vpc_id           = dependency.network.outputs.vpc_id
  enable_guardduty = true
  enable_cloudtrail = true
}
