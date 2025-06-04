# Root Module Outputs
# Aggregates outputs from all infrastructure modules

# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

# Security Outputs
output "nat_security_group_id" {
  description = "ID of the NAT instance security group"
  value       = module.security.nat_security_group_id
}

output "splunk_security_group_id" {
  description = "ID of the Splunk security group"
  value       = module.security.splunk_security_group_id
}

# Compute Outputs
output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = module.compute.nat_instance_id
}

output "nat_instance_public_ip" {
  description = "Public IP address of the NAT instance"
  value       = module.compute.nat_instance_public_ip
}

output "nat_instance_private_ip" {
  description = "Private IP address of the NAT instance"
  value       = module.compute.nat_instance_private_ip
}

# Splunk Outputs
output "splunk_instance_id" {
  description = "ID of the Splunk instance"
  value       = module.splunk.splunk_instance_id
}

output "splunk_instance_private_ip" {
  description = "Private IP address of the Splunk instance"
  value       = module.splunk.splunk_instance_private_ip
}

output "splunk_web_url" {
  description = "URL for Splunk Web interface (internal)"
  value       = module.splunk.splunk_web_url
}

# Cost Estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD"
  value = "~$21.80 (t3.nano NAT: $3.50, t3.small Splunk: $15.33, EBS: $2.97)"
}

# Access Information
output "connection_info" {
  description = "Connection information for accessing the infrastructure"
  value = {
    splunk_web_url = module.splunk.splunk_web_url
    vpc_id         = module.network.vpc_id
    nat_instance   = module.compute.nat_instance_public_ip
  }
}
