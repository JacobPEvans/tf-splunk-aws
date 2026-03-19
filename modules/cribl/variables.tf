# Cribl Module Variables

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "enable_cribl" {
  description = "Enable Cribl Stream and Edge instances"
  type        = bool
  default     = true
}

variable "cribl_stream_instance_type" {
  description = "Instance type for Cribl Stream (x86_64)"
  type        = string
  default     = "t3a.small"
}

variable "cribl_edge_instance_type" {
  description = "Instance type for Cribl Edge Windows instance (x86_64)"
  type        = string
  default     = "t3a.medium"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for instances (optional)"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs to attach to Cribl instances"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for instance placement"
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IP addresses with Cribl instances"
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "IAM instance profile name for Cribl instances"
  type        = string
}

variable "linux_ami_id" {
  description = "AMI ID for Cribl Stream (Amazon Linux 2 x86_64)"
  type        = string
}

variable "windows_ami_id" {
  description = "AMI ID for Cribl Edge (Windows Server 2022)"
  type        = string
}

variable "cribl_version" {
  description = "Cribl Stream/Edge version to install"
  type        = string
  default     = "4.10.1"
}

variable "cribl_build" {
  description = "Cribl build identifier for RPM package download"
  type        = string
  default     = "b68b2478"
}
