# Root Module Variables

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for instances (optional)"
  type        = string
  default     = null
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.nano"
}

variable "splunk_instance_type" {
  description = "Instance type for Splunk instance"
  type        = string
  default     = "t3.small"
}

variable "splunk_root_volume_size" {
  description = "Size of root volume for Splunk instance (GB)"
  type        = number
  default     = 20
}

variable "splunk_data_volume_size" {
  description = "Size of data volume for Splunk instance (GB)"
  type        = number
  default     = 50
}

variable "splunk_admin_password" {
  description = "Admin password for Splunk (use strong password)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.splunk_admin_password) >= 8
    error_message = "Splunk admin password must be at least 8 characters."
  }
}

variable "splunk_version" {
  description = "Splunk Enterprise version to install"
  type        = string
  default     = "9.3.2"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.splunk_version))
    error_message = "Splunk version must be in X.Y.Z format (e.g., 9.3.2)."
  }
}

variable "splunk_build" {
  description = "Splunk Enterprise build hash for the download URL"
  type        = string
  default     = "d8bb32809498"

  validation {
    condition     = can(regex("^[a-f0-9]{12}$", var.splunk_build))
    error_message = "Splunk build must be a 12-character hexadecimal string."
  }
}

variable "hec_allowed_cidrs" {
  description = "CIDR blocks allowed to send data to Splunk HEC (port 8088). Set to your on-prem/cloud source IPs."
  type        = list(string)
  default     = []
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access to instances (port 22). Set to [] to disable SSH, or provide specific CIDRs."
  type        = list(string)
  default     = []
}
