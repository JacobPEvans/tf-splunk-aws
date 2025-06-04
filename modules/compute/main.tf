# Compute Module - NAT Instance and Basic Compute Resources
# Handles cost-optimized NAT instance and basic compute infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values for consistent tagging
locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# User data script for NAT instance
locals {
  nat_user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    echo 'net.ipv4.conf.eth0.send_redirects = 0' >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
    
    # Configure iptables for NAT
    /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    /sbin/iptables -F FORWARD
    /sbin/iptables -A FORWARD -j ACCEPT
    
    # Save iptables rules
    service iptables save
    
    # Install SSM agent (should be pre-installed on Amazon Linux 2)
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent
  EOF
  )
}

# NAT Instance
resource "aws_instance" "nat" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.nat_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.nat_security_group_id]
  subnet_id              = var.public_subnet_ids[0] # Use first public subnet
  source_dest_check      = false # Required for NAT functionality

  user_data = local.nat_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
    
    tags = merge(local.common_tags, {
      Name = "${var.environment}-nat-instance-root"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-instance"
    Role = "nat"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for NAT instance
resource "aws_cloudwatch_log_group" "nat_instance" {
  name              = "/aws/ec2/${var.environment}-nat-instance"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-instance-logs"
  })
}
