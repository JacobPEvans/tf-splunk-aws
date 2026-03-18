# Root Terragrunt configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "tf-splunk-aws-state-useast2-${get_aws_account_id()}"
    key            = "tf-splunk-aws/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "tf-splunk-aws-locks-useast2"
  }
}

terraform {
  source = "./modules"

  extra_arguments "retry" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}

terragrunt_version_constraint = ">= 0.45"
terraform_version_constraint  = ">= 1.0"
