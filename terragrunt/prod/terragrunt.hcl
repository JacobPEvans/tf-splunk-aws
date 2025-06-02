# Terragrunt configuration for the prod environment
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules"
}

inputs = {
  environment = "prod"
}
