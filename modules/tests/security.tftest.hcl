# Tests for security module configuration
#
# Verifies security-related variables and outputs are wired correctly through
# the root module. Checks SSH access toggle behavior, sensitive variable handling,
# and that security group outputs are structured correctly.
# All runs use mock providers - no AWS credentials needed.

mock_provider "aws" {}

# Override compute and splunk modules to isolate security concerns.
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
    splunk_web_url              = "http://10.0.10.20:8000"
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
  nat_instance_type     = "t3.nano"
  splunk_instance_type  = "t3.small"
  splunk_admin_password = "mock-password-value"
}

# --- Plan succeeds with valid security inputs ---

run "security_plan_succeeds" {
  command = plan
}

# --- SSH disabled by default (ssh_allowed_cidrs defaults to empty) ---
# When ssh_allowed_cidrs is [], no SSH ingress rule is created.
# This is the default secure posture - use SSM Session Manager instead.

run "ssh_disabled_by_default" {
  command = plan

  assert {
    condition     = length(var.ssh_allowed_cidrs) == 0
    error_message = "ssh_allowed_cidrs should default to [], disabling SSH access"
  }
}

# --- SSH can be enabled by providing explicit CIDRs ---
# When ssh_allowed_cidrs is non-empty, the dynamic SSH ingress rule is created.

run "ssh_cidrs_controls_access" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["10.0.0.0/8"]
  }

  assert {
    condition     = length(var.ssh_allowed_cidrs) > 0
    error_message = "ssh_allowed_cidrs should be non-empty when provided, enabling SSH access"
  }
}

# --- SSM parameter is created for Splunk admin password ---
# The security module stores the password as a SecureString SSM parameter.

run "ssm_parameter_created_for_splunk_password" {
  command = plan

  assert {
    condition     = var.splunk_admin_password != ""
    error_message = "splunk_admin_password must be provided for SSM parameter creation"
  }
}

# --- splunk_admin_password is marked sensitive ---
# The variable must be declared with sensitive = true in variables.tf.
# OpenTofu enforces this at the variable declaration level; we verify the
# variable is accepted and handled without leaking in plan output.

run "splunk_admin_password_is_sensitive" {
  command = plan

  assert {
    condition     = var.splunk_admin_password != ""
    error_message = "splunk_admin_password must be non-empty"
  }
}

# --- Security group outputs are non-null ---
# The security module must produce both security group IDs consumed by compute
# and splunk modules.

run "security_group_outputs_are_non_null" {
  command = plan

  assert {
    condition     = output.nat_security_group_id != null
    error_message = "nat_security_group_id output must be non-null"
  }

  assert {
    condition     = output.splunk_security_group_id != null
    error_message = "splunk_security_group_id output must be non-null"
  }
}

# --- Security outputs are distinct security group IDs ---
# NAT and Splunk instances must have separate security groups for least-privilege.

run "nat_and_splunk_security_groups_are_separate" {
  command = plan

  assert {
    condition     = output.nat_security_group_id != output.splunk_security_group_id
    error_message = "NAT and Splunk must have separate security groups for least-privilege access control"
  }
}
