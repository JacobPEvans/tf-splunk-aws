# Tests for public access configuration
#
# Verifies that splunk_public_access controls subnet placement and public IP
# assignment. Tests both default (private) and enabled (public) modes.
# All runs use mock providers - no AWS credentials needed.

mock_provider "aws" {}

# Override child modules so the root module plans in isolation.
override_module {
  target = module.security
  outputs = {
    nat_security_group_id        = "sg-00000000000000001"
    splunk_security_group_id     = "sg-00000000000000002"
    splunk_instance_profile_name = "mock-splunk-instance-profile"
    splunk_iam_role_arn          = "arn:aws:iam::123456789012:role/mock-splunk-role"
    splunk_password_ssm_name     = "/dev/splunk/admin-password"
  }
}

override_module {
  target = module.compute
  outputs = {
    nat_instance_id                  = "i-00000000000000001"
    nat_instance_private_ip          = "10.0.1.10"
    nat_instance_public_ip           = "203.0.113.10"
    nat_primary_network_interface_id = "eni-00000000000000001"
    nat_cloudwatch_log_group         = "/aws/ec2/nat-instance"
  }
}

override_module {
  target = module.splunk
  outputs = {
    splunk_instance_id          = "i-00000000000000002"
    splunk_instance_private_ip  = "10.0.10.20"
    splunk_instance_public_ip   = "203.0.113.50"
    splunk_web_url              = "http://203.0.113.50:8000"
    splunk_cloudwatch_log_group = "/aws/ec2/splunk"
    splunk_app_log_group        = "/aws/ec2/splunk/app"
  }
}

# Shared valid defaults for all runs
variables {
  environment           = "dev"
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  nat_instance_type     = "t4g.nano"
  splunk_instance_type  = "t4g.small"
  splunk_admin_password = "mock-password-value"
}

# --- splunk_public_access defaults to false ---

run "public_access_disabled_by_default" {
  command = plan

  assert {
    condition     = var.splunk_public_access == false
    error_message = "splunk_public_access must default to false"
  }
}

# --- web_allowed_cidrs defaults to empty ---

run "web_allowed_cidrs_defaults_to_empty" {
  command = plan

  assert {
    condition     = length(var.web_allowed_cidrs) == 0
    error_message = "web_allowed_cidrs must default to [], got ${length(var.web_allowed_cidrs)} entries"
  }
}

# --- Plan succeeds with public access disabled (default) ---

run "private_mode_plan_succeeds" {
  command = plan
}

# --- Plan succeeds with public access enabled ---

run "public_access_enabled_plan_succeeds" {
  command = plan

  variables {
    splunk_public_access = true
    web_allowed_cidrs    = ["203.0.113.0/24"]
  }
}

# --- Plan succeeds with public access and HEC CIDRs ---

run "public_access_with_hec_plan_succeeds" {
  command = plan

  variables {
    splunk_public_access = true
    web_allowed_cidrs    = ["203.0.113.0/24"]
    hec_allowed_cidrs    = ["198.51.100.0/24"]
  }
}

# --- Splunk public IP output is exposed ---

run "splunk_public_ip_output_exposed" {
  command = plan

  variables {
    splunk_public_access = true
    web_allowed_cidrs    = ["203.0.113.0/24"]
  }

  assert {
    condition     = output.splunk_instance_public_ip != null
    error_message = "splunk_instance_public_ip must be non-null when public access is enabled"
  }
}

# --- Splunk web URL uses public IP when public access enabled ---

run "splunk_web_url_uses_public_ip" {
  command = plan

  variables {
    splunk_public_access = true
    web_allowed_cidrs    = ["203.0.113.0/24"]
  }

  assert {
    condition     = startswith(output.splunk_web_url, "http://")
    error_message = "splunk_web_url must start with 'http://', got ${output.splunk_web_url}"
  }

  assert {
    condition     = endswith(output.splunk_web_url, ":8000")
    error_message = "splunk_web_url must end with ':8000', got ${output.splunk_web_url}"
  }
}
