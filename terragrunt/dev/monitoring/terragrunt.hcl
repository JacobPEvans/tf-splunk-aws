# Monitoring module configuration for dev environment
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/monitoring"
}

dependency "network" {
  config_path = "../network"
}

dependency "splunk" {
  config_path = "../splunk"
}

inputs = {
  environment         = "dev"
  vpc_id              = dependency.network.outputs.vpc_id
  subnet_ids          = dependency.network.outputs.private_subnet_ids
  splunk_indexer_ips  = dependency.splunk.outputs.indexer_private_ips
}
