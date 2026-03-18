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

variable "splunk_admin_password" {
  description = "Admin password for Splunk (stored in SSM Parameter Store)"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access to instances (port 22). Set to [] to disable SSH."
  type        = list(string)
  default     = []
}

variable "hec_allowed_cidrs" {
  description = "CIDR blocks allowed to send data to Splunk HEC (port 8088). Set to your on-prem/cloud source IPs."
  type        = list(string)
  default     = []
}

variable "web_allowed_cidrs" {
  description = "CIDR blocks allowed access to Splunk Web (port 8000) from the internet. Set to [] to restrict to VPC only."
  type        = list(string)
  default     = []
}

variable "allow_all_ips" {
  description = "Override web_allowed_cidrs and hec_allowed_cidrs to 0.0.0.0/0."
  type        = bool
  default     = false
}

variable "smartstore_bucket_arn" {
  description = "ARN of the S3 bucket used for Splunk SmartStore remote storage"
  type        = string
}
