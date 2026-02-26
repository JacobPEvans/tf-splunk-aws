# Splunk Module Variables

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
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
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for instances (optional)"
  type        = string
  default     = null
}

variable "splunk_security_group_id" {
  description = "Security group ID for Splunk instance"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "splunk_instance_profile_name" {
  description = "IAM instance profile name for Splunk instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Splunk instance"
  type        = string
}

variable "splunk_version" {
  description = "Splunk Enterprise version to install"
  type        = string
  default     = "9.3.2"
}

variable "splunk_build" {
  description = "Splunk Enterprise build hash for the download URL"
  type        = string
  default     = "d8bb32809498"
}
