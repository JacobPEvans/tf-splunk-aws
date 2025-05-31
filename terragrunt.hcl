# Root Terragrunt configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-states"
    key            = "tf-splunk-aws/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "tf-locks"
  }
}

# Updated module paths to match the new structure
terraform {
  source = "../modules"
}
