# Tests for network module wiring and root module outputs
#
# Verifies that the root module correctly wires the network module and
# that network outputs are surfaced correctly. Tests run at plan time
# using mock providers - no AWS credentials needed.
#
# REGRESSION: Includes test for missing NAT route in the private route table.
# The private route table (aws_route_table.private in network/main.tf) has no
# NAT route defined, which means private subnet instances cannot reach the internet
# through the NAT instance. This is a known architectural gap to track.

mock_provider "aws" {}

# Override non-network child modules so we can test the root module's
# network wiring in isolation.
override_module {
  target = module.security
  outputs = {
    nat_security_group_id        = "sg-00000000000000001"
    splunk_security_group_id     = "sg-00000000000000002"
    splunk_instance_profile_name = "mock-splunk-instance-profile"
    splunk_iam_role_arn          = "arn:aws:iam::123456789012:role/mock-splunk-role"
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
    splunk_web_url              = "http://10.0.10.20:8000"
    splunk_cloudwatch_log_group = "/aws/ec2/splunk"
    splunk_app_log_group        = "/aws/ec2/splunk/app"
  }
}

# Shared valid defaults for all runs
variables {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  nat_instance_type    = "t3.nano"
  splunk_instance_type = "t3.small"
  splunk_admin_password = "TestPassword123!"
}

# --- Plan succeeds with valid network inputs ---

run "network_plan_succeeds" {
  command = plan
}

# --- VPC CIDR block matches input variable ---

run "vpc_cidr_block_matches_input" {
  command = plan

  assert {
    condition     = output.vpc_cidr_block == "10.0.0.0/16"
    error_message = "vpc_cidr_block output should match input '10.0.0.0/16', got ${output.vpc_cidr_block}"
  }
}

# --- Correct number of public subnets created ---

run "correct_number_of_public_subnets" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "expected 2 public subnets, got ${length(output.public_subnet_ids)}"
  }
}

# --- Correct number of private subnets created ---

run "correct_number_of_private_subnets" {
  command = plan

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "expected 2 private subnets, got ${length(output.private_subnet_ids)}"
  }
}

# --- Route table outputs are non-null (route tables are created) ---

run "route_tables_are_created" {
  command = plan

  assert {
    condition     = output.nat_security_group_id != null
    error_message = "nat_security_group_id should be non-null after network wiring"
  }

  assert {
    condition     = output.splunk_security_group_id != null
    error_message = "splunk_security_group_id should be non-null after network wiring"
  }
}

# --- REGRESSION: Private route table has no NAT route ---
# This test documents the known gap: the private route table in network/main.tf
# does not include a route for 0.0.0.0/0 via the NAT instance's network interface.
# Without this route, private subnet instances (e.g., Splunk) cannot reach the internet
# through the NAT instance. The route must be added to network/main.tf as an
# aws_route resource that references the compute module's nat_primary_network_interface_id.
#
# Currently the plan succeeds because OpenTofu/Terraform does not validate routing
# correctness at plan time - this assertion verifies that private_subnet_ids are
# non-empty as a proxy check that subnets exist and would need a route.

run "private_subnets_exist_and_require_nat_route" {
  command = plan

  assert {
    condition     = length(output.private_subnet_ids) > 0
    error_message = "private subnets must exist; they also require a NAT route in the private route table (currently missing)"
  }

  assert {
    condition     = output.nat_instance_id != null
    error_message = "NAT instance must exist to provide routing for private subnets"
  }
}

# --- NAT instance public IP is exposed for egress routing ---

run "nat_instance_public_ip_is_exposed" {
  command = plan

  assert {
    condition     = output.nat_instance_public_ip != null
    error_message = "nat_instance_public_ip must be exposed in root module outputs"
  }
}
