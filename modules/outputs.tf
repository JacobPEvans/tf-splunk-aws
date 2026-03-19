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

output "splunk_instance_public_ip" {
  description = "Public IP address of the Splunk instance (null when in private subnet)"
  value       = module.splunk.splunk_instance_public_ip
}

output "splunk_web_url" {
  description = "URL for Splunk Web interface (uses public IP when available)"
  value       = module.splunk.splunk_web_url
}

# Cribl Outputs
output "cribl_stream_instance_id" {
  description = "ID of the Cribl Stream instance (null when disabled)"
  value       = module.cribl.cribl_stream_instance_id
}

output "cribl_stream_private_ip" {
  description = "Private IP of the Cribl Stream instance (null when disabled)"
  value       = module.cribl.cribl_stream_private_ip
}

output "cribl_stream_public_ip" {
  description = "Public IP of the Cribl Stream instance (null when disabled)"
  value       = module.cribl.cribl_stream_public_ip
}

output "cribl_stream_web_url" {
  description = "URL for Cribl Stream Web UI (null when disabled)"
  value       = module.cribl.cribl_stream_web_url
}

output "cribl_edge_instance_id" {
  description = "ID of the Cribl Edge instance (null when disabled)"
  value       = module.cribl.cribl_edge_instance_id
}

output "cribl_edge_private_ip" {
  description = "Private IP of the Cribl Edge instance (null when disabled)"
  value       = module.cribl.cribl_edge_private_ip
}

output "cribl_edge_public_ip" {
  description = "Public IP of the Cribl Edge instance (null when disabled)"
  value       = module.cribl.cribl_edge_public_ip
}

# Security Group Outputs (Cribl)
output "internal_security_group_id" {
  description = "ID of the internal cluster security group (null when Cribl disabled)"
  value       = module.security.internal_security_group_id
}

output "cribl_security_group_id" {
  description = "ID of the Cribl security group (null when Cribl disabled)"
  value       = module.security.cribl_security_group_id
}

# SmartStore S3 Bucket
output "smartstore_bucket_name" {
  description = "Name of the S3 bucket used for Splunk SmartStore remote storage"
  value       = aws_s3_bucket.smartstore.bucket
}

# Cost Estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (always-on vs auto-lifecycle)"
  value       = var.enable_cribl ? "Always-on: ~$77/mo (NAT: $2.52, Splunk: $12.18, Stream: $13.74, Edge/Win: $42.34, EBS: $6.17, S3: ~$0.50) | Auto-lifecycle Splunk: ~$68/mo" : "Always-on: ~$18.17/mo (NAT: $2.52, Splunk: $12.18, EBS: $2.97, S3: ~$0.50) | Auto-lifecycle: ~$9/mo (Splunk 25%: ~$3.05)"
}

# Access Information
output "connection_info" {
  description = "Connection information for accessing the infrastructure"
  value = merge(
    {
      splunk_web_url   = module.splunk.splunk_web_url
      splunk_public_ip = module.splunk.splunk_instance_public_ip
      vpc_id           = module.network.vpc_id
      nat_instance     = module.compute.nat_instance_public_ip
    },
    var.enable_cribl ? {
      cribl_stream_web_url = module.cribl.cribl_stream_web_url
      cribl_edge_ip        = module.cribl.cribl_edge_private_ip
    } : {}
  )
}
