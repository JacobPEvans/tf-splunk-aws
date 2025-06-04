# Compute Module Variables

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.nano"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for instances (optional)"
  type        = string
  default     = null
}

variable "nat_security_group_id" {
  description = "Security group ID for NAT instance"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}
