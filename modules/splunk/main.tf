# Splunk Module - Splunk-specific instances and configuration
# Handles Splunk infrastructure deployment and configuration

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

# User data script for Splunk instance
locals {
  splunk_user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    
    # Install required packages
    yum install -y wget tar
    
    # Install SSM agent (should be pre-installed on Amazon Linux 2)
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent
    
    # Create splunk user
    useradd -r -m -s /bin/bash splunk
    
    # Download and install Splunk (using a basic installation)
    cd /opt
    wget -O splunk-8.2.6-a6fe1ee8894b-Linux-x86_64.tgz "https://download.splunk.com/products/splunk/releases/8.2.6/linux/splunk-8.2.6-a6fe1ee8894b-Linux-x86_64.tgz"
    tar -xzf splunk-8.2.6-a6fe1ee8894b-Linux-x86_64.tgz
    chown -R splunk:splunk /opt/splunk
    
    # Start Splunk and accept license
    sudo -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "${var.splunk_admin_password}"
    
    # Enable Splunk to start at boot
    /opt/splunk/bin/splunk enable boot-start -user splunk
    
    # Configure basic settings
    sudo -u splunk /opt/splunk/bin/splunk set web-port 8000
    sudo -u splunk /opt/splunk/bin/splunk restart
  EOF
  )
}

# Splunk Instance
resource "aws_instance" "splunk" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.splunk_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.splunk_security_group_id]
  subnet_id              = var.private_subnet_ids[0] # Use first private subnet
  iam_instance_profile   = var.splunk_instance_profile_name

  user_data = local.splunk_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.splunk_root_volume_size
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-splunk-root"
    })
  }

  # Additional EBS volume for Splunk data
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.splunk_data_volume_size
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-splunk-data"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-instance"
    Role = "splunk"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for Splunk instance
resource "aws_cloudwatch_log_group" "splunk" {
  name              = "/aws/ec2/${var.environment}-splunk"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-logs"
  })
}

# CloudWatch Log Group for Splunk application logs
resource "aws_cloudwatch_log_group" "splunk_app" {
  name              = "/splunk/${var.environment}"
  retention_in_days = 90

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-app-logs"
  })
}
