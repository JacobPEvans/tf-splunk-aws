# Compute module configuration for dev environment
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/compute"
}

dependency "network" {
  config_path = "../network"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  environment = "dev"
  vpc_id      = dependency.network.outputs.vpc_id
  subnet_ids  = dependency.network.outputs.private_subnet_ids
}
