# Terragrunt configuration for the stg environment
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules"
}

inputs = {
  environment = "stg"
}
