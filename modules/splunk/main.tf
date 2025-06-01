# Comprehensive Splunk module for AWS deployment
# Supports indexers, search heads, forwarders, and cluster management

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Splunk will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Splunk deployment"
  type        = list(string)
}

variable "splunk_ami_id" {
  description = "AMI ID for Splunk instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "indexer_config" {
  description = "Configuration for Splunk indexers"
  type = object({
    count         = number
    instance_type = string
    disk_size     = number
  })
  default = {
    count         = 2
    instance_type = "m5.large"
    disk_size     = 100
  }
}

variable "search_head_config" {
  description = "Configuration for Splunk search heads"
  type = object({
    count         = number
    instance_type = string
    disk_size     = number
  })
  default = {
    count         = 1
    instance_type = "m5.medium"
    disk_size     = 50
  }
}

variable "forwarder_config" {
  description = "Configuration for Universal Forwarders"
  type = object({
    count         = number
    instance_type = string
    disk_size     = number
  })
  default = {
    count         = 0
    instance_type = "t3.micro"
    disk_size     = 20
  }
}

variable "enable_clustering" {
  description = "Enable Splunk clustering (requires minimum 3 indexers)"
  type        = bool
  default     = false
}

variable "splunk_admin_password" {
  description = "Admin password for Splunk (use AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# Security Group for Splunk components
resource "aws_security_group" "splunk" {
  name_prefix = "${var.environment}-splunk-"
  vpc_id      = var.vpc_id

  # Splunk Web (8000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Splunk Management (8089)
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Splunk Indexing (9997)
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Splunk Replication (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-sg"
  })
}

# IAM Role for Splunk instances
resource "aws_iam_role" "splunk" {
  name = "${var.environment}-splunk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "splunk" {
  name = "${var.environment}-splunk-profile"
  role = aws_iam_role.splunk.name
}

# Splunk Indexers
resource "aws_instance" "indexer" {
  count = var.indexer_config.count

  ami                    = var.splunk_ami_id
  instance_type          = var.indexer_config.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.splunk.id]
  iam_instance_profile   = aws_iam_instance_profile.splunk.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.indexer_config.disk_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/indexer-userdata.sh", {
    environment         = var.environment
    splunk_password     = var.splunk_admin_password
    indexer_count       = var.indexer_config.count
    enable_clustering   = var.enable_clustering
    instance_index      = count.index
  }))

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-indexer-${count.index + 1}"
    Role = "indexer"
  })
}

# Splunk Search Heads
resource "aws_instance" "search_head" {
  count = var.search_head_config.count

  ami                    = var.splunk_ami_id
  instance_type          = var.search_head_config.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.splunk.id]
  iam_instance_profile   = aws_iam_instance_profile.splunk.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.search_head_config.disk_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/search-head-userdata.sh", {
    environment       = var.environment
    splunk_password   = var.splunk_admin_password
    indexer_ips       = aws_instance.indexer[*].private_ip
    enable_clustering = var.enable_clustering
  }))

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-search-head-${count.index + 1}"
    Role = "search-head"
  })

  depends_on = [aws_instance.indexer]
}

# Universal Forwarders (optional)
resource "aws_instance" "forwarder" {
  count = var.forwarder_config.count

  ami                    = var.splunk_ami_id
  instance_type          = var.forwarder_config.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.splunk.id]
  iam_instance_profile   = aws_iam_instance_profile.splunk.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.forwarder_config.disk_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/forwarder-userdata.sh", {
    environment     = var.environment
    splunk_password = var.splunk_admin_password
    indexer_ips     = aws_instance.indexer[*].private_ip
  }))

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-forwarder-${count.index + 1}"
    Role = "forwarder"
  })

  depends_on = [aws_instance.indexer]
}
