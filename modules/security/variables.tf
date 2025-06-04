# Security Module Variables

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "List of CIDR blocks for VPC access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "enable_ssh_access" {
  description = "Whether to enable SSH access to instances"
  type        = bool
  default     = false
}
