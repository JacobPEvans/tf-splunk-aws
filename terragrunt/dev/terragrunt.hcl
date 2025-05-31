# Terragrunt configuration for the dev environment
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../..//modules"
}

inputs = {
  environment = "dev"
}
